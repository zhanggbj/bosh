require 'logging'

module Bosh::LoggingHelper
  def self.create_logger(name, config={})
    logger = Logging::Logger.new(name)
    if config[:filename]
      logger.add_appenders(
        Logging.appenders.file(
          "#{name}File",
          filename: config[:filename]
        )
      )
    elsif config[:io]
      logger.add_appenders(
        Logging.appenders.io(
          "#{name}IO",
          config[:io]
        )
      )
    else
      logger.add_appenders(
        Logging.appenders.stdout("#{name}IO")
      )
    end

    if config[:level]
      logger.level = Logging.levelify(config[:level])
    end

    logger
  end
end
