# Notes used to take their colour from id mod 6; store it so it can be changed.
class AddColorToNotes < ActiveRecord::Migration[8.1]
  COLORS = %w[yellow blue green pink purple gray].freeze

  def up
    add_column :notes, :color, :string, default: "yellow", null: false
    COLORS.each_with_index do |color, index|
      execute "UPDATE notes SET color = '#{color}' WHERE id % #{COLORS.size} = #{index}"
    end
  end

  def down
    remove_column :notes, :color
  end
end
