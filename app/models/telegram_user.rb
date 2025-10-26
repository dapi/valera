class TelegramUser < ApplicationRecord
  has_one :chat

  # Returns user's name for welcome message interpolation
  def name
    first_name.presence || ("@#{username}" if username).to_s || '#' + id.to_s
  end

  def full_name
    [first_name, last_name].compact.join(' ').strip
  end

  def self.find_or_create_by_telegram_data!(data)
    tu = create_with(
      data.slice('first_name', 'last_name', 'username', 'photo_url')
    )
      .find_or_create_by!(id: data.fetch('id'))

    tu.update_from_chat! data
    tu
  end

  # chat =>
  # {"id"=>943084337, "first_name"=>"Danil", "last_name"=>"Pismenny", "username"=>"pismenny", "type"=>"private"}
  def update_from_chat!(chat)
    assign_attributes chat.slice(*%w[first_name last_name username])
    return unless changed?

    save!
  end
end
