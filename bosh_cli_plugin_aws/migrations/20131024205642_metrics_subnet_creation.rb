class MetricsSubnetCreation < Bosh::Aws::Migration
  include Bosh::Aws::MigrationHelper

  def execute
    vpc_receipt = load_receipt("aws_vpc_receipt")

    vpc = Bosh::Aws::VPC.find(ec2, vpc_receipt["vpc"]["id"])

    new_az = vpc_receipt["original_configuration"]["vpc"]["subnets"]["cf1"]["availability_zone"]

    new_subnet_name = "metrics1"
    subnets = {
      new_subnet_name => {"availability_zone" => new_az, "cidr" => "10.10.49.0/24", "default_route" => "cf_nat_box1"},
    }

    existing_subnets = vpc.subnets

    unless existing_subnets.keys.include?(new_subnet_name)
      vpc.create_subnets(subnets) { |msg| say "  #{msg}" }
      vpc.setup_subnet_routes(subnets) { |msg| say "  #{msg}" }

      vpc_receipt["vpc"]["subnets"] = vpc.subnets
    end
  ensure
    save_receipt("aws_vpc_receipt", vpc_receipt)
  end
end
