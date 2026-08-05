ApplicationRecord.transaction do
  Vote.delete_all
  Candidacy.delete_all
  Election.delete_all
  Candidate.delete_all

  candidate_names = [
    "João da Silva",
    "Maria de Oliveira",
    "José dos Santos",
    "Ana Souza",
    "Carlos Pereira",
    "Francisca Almeida"
  ]

  candidates = candidate_names.index_with do |name|
    Candidate.create!(name:)
  end

  scenarios = {
    "votação da semana 1" => {
      status: :closed,
      results: {
        "João da Silva" => 8,
        "Maria de Oliveira" => 5,
        "José dos Santos" => 2
      }
    },
    "votação da semana 2" => {
      status: :open,
      results: {
        "Ana Souza" => 4,
        "Carlos Pereira" => 4,
        "João da Silva" => 1
      }
    },
    "votação da semana 3" => {
      status: :pending,
      results: {
        "Maria de Oliveira" => 0,
        "José dos Santos" => 0,
        "Francisca Almeida" => 0
      }
    }
  }

  scenarios.each do |title, scenario|
    election = Election.create!(title:, status: scenario.fetch(:status))

    scenario.fetch(:results).each do |candidate_name, vote_count|
      candidacy = Candidacy.create!(
        election:,
        candidate: candidates.fetch(candidate_name)
      )

      vote_count.times do
        candidacy.votes.create!
      end
    end
  end
end
