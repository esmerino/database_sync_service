class DatabaseSyncService
  def initialize(external_db_url, options = {})
    current_db       = ActiveRecord::Base.connection_db_config.configuration_hash

    @external_db_url = external_db_url

    @host            = current_db[:host]
    @db_name         = current_db[:database]
    @user_name       = current_db[:username]
    @password        = current_db[:password]
  end

  def execute
    raise 'Cannot be executed in production environment' if Rails.env.production?

    Rails.logger.info('1) Build dump file')
    build_dump_file

    Rails.logger.info('2) Restore dump file')
    restore_dump

    Rails.logger.info('3) Remove dump file')
    remove_dump_file
  end

  private

  attr_reader :external_db_url, :host, :db_name, :user_name, :password, :heroku

  def build_dump_file
    system("#{dump_command} | #{anonimize_dump}")
  end

  def restore_dump
    system(restore_command)
  end

  def remove_dump_file
    system("rm -f #{dump_file_name}")
  end

  def dump_command
    "pg_dump -x -v -O --disable-triggers #{external_db_url}"
  end

  def restore_command
    "PGPASSWORD=#{password} psql -U #{user_name} -h #{host} -d #{db_name} -f #{dump_file_name}"
  end

  def anonimize_dump
    "pg_dump_anonymize -d #{anonimization_definition_file_name} > #{dump_file_name}"
  end

  def dump_file_name
    'db_dump.sql'
  end
end
