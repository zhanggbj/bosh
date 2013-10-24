require 'spec_helper'
require '20131024205642_metrics_subnet_creation'

describe MetricsSubnetCreation do
  include MigrationSpecHelper

  subject { described_class.new(config, '')}

  before do
    subject.stub(:load_receipt).and_return(YAML.load_file(asset "test-output.yml"))
    Bosh::Aws::VPC.should_receive(:find).with(ec2, "vpc-13724979").and_return(vpc)
  end

  let(:vpc) { double("vpc") }
  let(:metrics1_id) {"subnet-abc123"}

  it "adds missing subnets for a secondary AZ" do
    subnets = {
      "metrics1" => {"availability_zone" => "us-east-1c", "cidr" => "10.10.49.0/24", "default_route" => "cf_nat_box1"}
    }

    vpc.should_receive(:create_subnets).with(subnets)
    vpc.should_receive(:setup_subnet_routes).with(subnets)

    vpc.should_receive(:subnets).and_return(
      {
        "cf1" => "subnet-xxxxxxx1",
      },
      {
        "cf1" => "subnet-xxxxxxx1",
        "metrics1" => metrics1_id
      }
    )

    subject.should_receive(:save_receipt) { |filename, contents|
      filename.should == "aws_vpc_receipt"
      contents["vpc"]["id"].should == "vpc-13724979" # quickly check we didn't wipe anything out
      contents["vpc"]["subnets"]["cf1"].should == "subnet-xxxxxxx1" # quickly check other subnets are there
      contents["vpc"]["subnets"]["metrics1"].should == metrics1_id
    }

    subject.execute
  end

  it "does not create the new subnets if they already exist" do
    vpc.should_receive(:subnets).and_return(
      {
        "cf1" => "subnet-xxxxxxx1",
        "metrics1" => {"availability_zone" => "us-east-1c", "cidr" => "10.10.49.0/24", "default_route" => "cf_nat_box1"}
      }
    )

    vpc.should_not_receive(:create_subnets)
    vpc.should_not_receive(:setup_subnet_routes)

    subject.should_receive(:save_receipt) { |filename, contents|
      contents.should == YAML.load_file(asset "test-output.yml")
    }

    subject.execute
  end
end
