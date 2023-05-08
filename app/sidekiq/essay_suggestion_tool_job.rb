class EssaySuggestionToolJob
  include Sidekiq::Job

  FIRST_BULLET_REGEX  = /((?<=1\)).*(?=2\))|(?<=1\.).*(?=2\.)|(?<=1\:).*(?=2\:)|(?<=Step 1\:).*(?=Step 2\:))/m
  SECOND_BULLET_REGEX = /((?<=2\)).*(?=3\))|(?<=2\.).*(?=3\.)|(?<=2\:).*(?=3\:)|(?<=Step 2\:).*(?=Step 3\:))/m
  THIRD_BULLET_REGEX  = /((?<=3\)).*|(?<=3\.).*|(?<=3\:).*|(?<=Step 3\:).*)/m

  def perform year_level, type_of_paragraph, essay_type, essay_question, your_paragraph, model, email_address
    @year_level = year_level
    @type_of_paragraph = type_of_paragraph
    @essay_type = essay_type
    @essay_question = essay_question
    @your_paragraph = your_paragraph
    @client = OpenAI::Client.new
    @model = model

    if @model == "text-davinci-003"
      response_data = use_completion_api
    elsif ["gpt-3.5-turbo", "gpt-4"].include?(@model)
      response_data =  use_chat_api
    end

    suggestions_array = handle_response(response_data)

    essay_suggester = EssaySuggester.create(
      year_level: @year_level,
      type_of_paragraph: @type_of_paragraph,
      essay_type: @essay_type,
      essay_question: @essay_question,
      your_paragraph: @your_paragraph,
      suggestions_array: suggestions_array
    )

    OpenaiMailer.send_response(type_of_paragraph, essay_type, email_address, essay_suggester.id).deliver_now
  end

  private

   def use_completion_api
    response = @client.completions(
      parameters: {
          model: "text-davinci-003",
          temperature: 0.9,
          prompt: design_prompt_v2,
          max_tokens: 1500,
      })
    response["choices"][0]["text"]
  end

  def use_chat_api
    response = @client.chat(
      parameters:{
        model: @model,
        messages: [{"role": "user", "content": design_prompt_v2}]
      })

    response["choices"][0]["message"]["content"]
  end

  def handle_response(text)
    text_array = []
    text_array.push text.match(FIRST_BULLET_REGEX).to_s
    text_array.push text.match(SECOND_BULLET_REGEX).to_s
    text_array.push modify_third_point(text.match(THIRD_BULLET_REGEX).to_s)
    text_array
  end

  def modify_third_point(text)
    text.split("\n\n")[0] rescue ""
  end

  def design_prompt
    return text_analytics_prompt if @essay_type == "Text Analysis"
    return comparative_prompt if @essay_type == "Comparative"
    return persuasive_prompt if @essay_type == "Persuasive"
  end

  def depth_of_suggestions
    return "in specific but simple terms" if ["7", "8", "9"].include?(@year_level)
    return "in specific detail" if ["10", "11", "12"].include?(@year_level)
  end

  def text_analysis_introduction
    "- The sentences aren't overly long, unclear or complex\n" \
    "- The writing has answered or used the wording of the question\n" \
    "- A clear and concise thesis statement is featured\n" \
    "- Each argument that will be discussed in the essay is mentioned\n" \
    "- The studied text has been clearly introduced with supporting context to assist the reader in understanding the text\n"
  end

  def text_analysis_body_paragraph
    "- The sentences aren't overly long, unclear or complex\n" \
    "- The writing has answered or used the wording of the question\n" \
    "- There is a minimum of three pieces of evidence from the text, which have each been explained or analysed to support the argument\n" \
    "- There is a clear topic sentence which captures what the paragraph is about\n" \
    "- A concluding sentence that sums up the paragraph is featured and connects back to the topic sentence\n" \
    "- The writing follows a logical and organised structure\n" \
    "- Transitional words are used to connect evidence and analyses.\n"
  end

  def text_analysis_conclusion
    "- The sentences aren't overly long, unclear or complex\n" \
    "- The writing has answered or used the wording of the question\n" \
    "- The studied text has been reintroduced\n" \
    "- A clear and concise thesis statement is featured\n" \
    "- The arguments mentioned in the body of the essay have been summarised\n"
  end

  def comparative_introduction
    "- The sentences aren't overly long, unclear or complex\n" \
    "- The writing has answered or used the wording of the question\n" \
    "- A clear and concise thesis statement is featured\n" \
    "- Each argument that will be discussed in the essay is mentioned\n" \
    "- Both studied texts have been clearly introduced with supporting context to assist the reader in understanding both of the texts\n" \
    "- A clear link has been established between both texts\n"
  end

  def comparative_body_paragraph
    "- The sentences aren't overly long, unclear or complex\n" \
    "- The writing has answered or used the wording of the question\n" \
    "- There is a minimum of three pieces of evidence from the text, which have each been explained or analysed to support the argument\n" \
    "- There is a clear topic sentence which captures what the paragraph is about\n" \
    "- The writing has mentioned and analysed both texts, with reference to the context of each\n" \
    "- A concluding sentence that sums up the paragraph is featured and connects back to the topic sentence\n" \
    "- The writing follows a logical and organised structure\n" \
    "- Transitional words are used to connect evidence and analyses, specifically between texts\n"
  end

  def comparative_conclusion
    "- The sentences aren't overly long, unclear or complex\n" \
    "- The writing has answered or used the wording of the question\n" \
    "- Both studied texts have been reintroduced\n" \
    "- A clear and concise thesis statement is featured\n" \
    "- The arguments mentioned in the body of the essay have been summarised\n"
  end

  def persuasive_introduction
    "- The sentences aren't overly long, unclear or complex\n" \
    "- The writing has answered or used the wording of the question\n" \
    "- There is an attention grabbing opening that adds depth to the question\n" \
    "- Each argument that will be discussed in the essay is mentioned\n" \
    "- A clear and concise thesis statement is featured\n" \
    "- Some context around the topic has been included\n"
  end

  def persuasive_body_paragraph
    "- The sentences aren't overly long, unclear or complex\n" \
    "- The writing has answered or used the wording of the question\n" \
    "- There is a clear topic sentence which captures what the paragraph is about\n" \
    "- A concluding sentence that sums up the paragraph is featured\n" \
    "- The writing follows a logical and organised structure\n" \
    "- Transitional words are used to connect evidence and analyses\n" \
    "- Counter-arguments have been included but also reasoning to refute them \n"
  end

  def persuasive_conclusion
    "- The sentences aren't overly long, unclear or complex\n" \
    "- The writing has answered or used the wording of the question\n" \
    "- A clear and concise thesis statement is featured\n" \
    "- The arguments mentioned in the body of the essay have been summarised\n" \
    "- There is a call to action\n"
  end

  def text_analysis_conditions
    return text_analysis_introduction if @type_of_paragraph == "Introduction"
    return text_analysis_body_paragraph if @type_of_paragraph == "Body Paragraph"
    return text_analysis_conclusion if @type_of_paragraph == "Conclusion"
  end

  def comparative_conditions
    return comparative_introduction if @type_of_paragraph == "Introduction"
    return comparative_body_paragraph if @type_of_paragraph == "Body Paragraph"
    return comparative_conclusion if @type_of_paragraph == "Conclusion"
  end

  def persuasive_conditions
    return persuasive_introduction if @type_of_paragraph == "Introduction"
    return persuasive_body_paragraph if @type_of_paragraph == "Body Paragraph"
    return persuasive_conclusion if @type_of_paragraph == "Conclusion"
  end

  def essay_suggestions
    return text_analysis_conditions if @essay_type == "Text Analysis"
    return comparative_conditions if @essay_type == "Comparative"
    return persuasive_conditions if @essay_type == "Persuasive"
  end

  def design_prompt_v2
    "I am a Year #{@year_level} student and I was given this essay prompt for a #{@essay_type} essay:\n\n" \
    "#{@essay_question}\n\n" \
    "Can you please provide me three steps of improvement for my writing. Could this be formatted in this way:\n"\
    "1)\n" \
    "2)\n" \
    "3)\n" \
    "However, none of these steps are to provide an example or what I could write as I don't want to be plagiarised or have the AI write it for me.\n" \
    "Can you give me three numbered steps I could take to improve my #{@type_of_paragraph}. Could you explain each step #{depth_of_suggestions} why I should include them. When referring to my writing, you cannot provide or write an example for me, instead you must provide clear and specific instructions. Please format the response with both the step and reason in the same paragraph.\n\n" \
    "Can you base the three steps on the following conditions. If the writing doesn’t meet one or more of these conditions please suggest a step and reason to meet that condition. If all of the conditions have been met other suggestions on the writing can be made. Only three steps are to be provided though. These are the conditions ranked in order of importance:\n" \
    "#{essay_suggestions}\n" \
    "Here is my #{@type_of_paragraph}:\n" \
    "#{@your_paragraph}"
  end

 def text_analytics_prompt
    "I am a Year #{@year_level} student and I was given the essay prompt:\"#{@essay_question}\".\n"\
    "This is a text analysis #{@type_of_paragraph}. This essay is meant to focus on a particular theme of literary element within a specific work of literature.\n"\
    "What are three steps I could do to improve my #{@type_of_paragraph}? Could you explain why I should do those improvements without rewriting it for me?\n"\
    "#{@your_paragraph}"
  end

  def comparative_prompt
    "I am a Year #{@year_level} student and I was given the essay prompt:\"#{@essay_question}\".\n"\
    "This is a comparative #{@type_of_paragraph}. This essay is meant to compare and contrast two or more texts focusing on a particular theme or literary element.\n"\
    "What are three steps I could do to improve my #{@type_of_paragraph}? Could you explain why I should do those improvements without rewriting it for me?\n"\
    "#{@your_paragraph}"
  end

  def persuasive_prompt
    "I am a Year #{@year_level} student and I was given the essay prompt:\"#{@essay_question}\".\n"\
    "This is a persuasive #{@type_of_paragraph}. This essay is meant to argue for a particular reason or viewpoint on a controversial issue.\n"\
    "What are three steps I could do to improve my #{@type_of_paragraph}? Could you explain why I should do those improvements without rewriting it for me?\n"\
    "#{@your_paragraph}"
  end
end
