class CreateEssaySuggesters < ActiveRecord::Migration[6.1]
  def change
    create_table :essay_suggesters do |t|
      t.string :year_level
      t.string :type_of_paragraph
      t.string :essay_type
      t.string :essay_question
      t.string :your_paragraph
      t.json :suggestions_array
      t.timestamps
    end
  end
end
