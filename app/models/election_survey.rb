class ElectionSurvey < ApplicationRecord
  validates :slug, uniqueness: true
  validates :election_year, presence: true
  validates :election_type, presence: true

  before_save :generate_slug

  def self.filter_nonresponders(survey, candidates)
    candidates.reject do |c|
      survey.responses_for_candidate(c).reject do |r|
        r.body.strip.blank?
      end.any?
    end
  end

  def to_param
    self.slug
  end

  def title
    [election_year.to_s, election_type.to_s.try(:capitalize)].compact.join(' ')
  end

  def import_from_csv(file)
    ElectionSurveyImporter.csv_to_params(self, file)
    self.save!
  end
  
  def has_responses_from?(candidate)
    responses_for_candidate(candidate).reject do |r|
      r.body.strip.blank?
    end.any?
  end

  def tracker_url_for(candidate)
    Rails.cache.fetch("#{ self.slug }/tracker/#{ candidate.area }/#{ candidate.slug }") do
      url = "https://counciltracker.ie/councillors/#{ candidate.slug }"
      res = HTTP.get(url)
      if res.status.to_i == 200
        url
      else
        nil
      end
    end
  end
  
  # children

  def candidate_objects
    @candidate_objects ||= self.candidates.to_a.
      map { |h| OpenStruct.new(h) }
  end

  def question_objects
    @question_objects ||= self.questions.to_a.
      map { |h| OpenStruct.new(h) }
  end

  def response_objects
    @response_objects ||= self.responses.to_a.
      map { |h| OpenStruct.new(h) }
  end

  def party_objects
    @party_objects ||= self.parties.to_a.
      map { |h| OpenStruct.new(h) }
  end

  def area_objects
    @area_objects ||= self.areas.to_a.
      map { |h| OpenStruct.new(h) }.sort_by(&:name)
  end

  # finders

  def find_area(slug)
    self.area_objects.each do |area|
      return area if area.slug == slug
    end
    nil
  end

  def find_party(slug)
    self.party_objects.each do |party|
      return party if party.slug == slug
    end
    nil
  end

  def find_candidate(slug)
    self.candidate_objects.each do |candidate|
      return candidate if candidate.slug == slug
    end
    nil
  end

  def find_question(position)
    self.question_objects.each do |question|
      return question if question.position == position.try(:to_i)
    end
    nil
  end

  # children for children

  def responses_for_question(question)
    self.response_objects.reject { |r| r.question != question.position }
  end

  def responses_for_candidate(candidate)
    self.response_objects.reject { |r| r.candidate != candidate.slug }
  end

  def response_for(question, candidate)
    (self.responses_for_question(question) & self.responses_for_candidate(candidate)).first
  end

  def candidates_for_area(area)
    self.candidate_objects.reject { |c| c.area != area.slug }
  end

  def candidates_for_party(party)
    self.candidate_objects.reject { |c| c.party != party.slug }
  end

  private

  def generate_slug
    self.slug = self.title.parameterize
  end
end