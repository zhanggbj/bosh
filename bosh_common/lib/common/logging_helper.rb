require 'logging'

module Bosh::LoggingHelper
  def self.create_logger(name, config={})
    logger = Logging::Logger.new(name)
    appender_config = {}
    appender_config[:layout] = config[:layout] if config[:layout]
    if config[:filename]
      appender_config[:filename] = config[:filename]
      logger.add_appenders(Logging.appenders.file("#{name}File", appender_config))
    elsif config[:io]
      logger.add_appenders(Logging.appenders.io("#{name}IO", config[:io], appender_config))
    else
      logger.add_appenders(Logging.appenders.stdout("#{name}StdOut", appender_config))
    end

    if config[:level]
      logger.level = Logging.levelify(config[:level])
    end

    logger
  end
end
