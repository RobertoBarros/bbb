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
      status: :closed,
      results: {
        "Ana Souza" => 6,
        "Carlos Pereira" => 6,
        "João da Silva" => 3
      }
    },
    "votação da semana 3" => {
      status: :closed,
      results: {
        "Francisca Almeida" => 9,
        "José dos Santos" => 7,
        "Maria de Oliveira" => 4
      }
    },
    "votação da semana 4" => {
      status: :closed,
      results: {
        "Carlos Pereira" => 5,
        "Ana Souza" => 4,
        "Francisca Almeida" => 2
      }
    },
    "votação da semana 5" => {
      status: :open,
      results: {
        "Ana Souza" => 4,
        "Carlos Pereira" => 4,
        "João da Silva" => 1
      }
    },
    "votação da semana 6" => {
      status: :pending,
      results: {
        "Maria de Oliveira" => 0,
        "José dos Santos" => 0,
        "Francisca Almeida" => 0
      }
    }
  }

  scenarios.each do |title, scenario|
    status = scenario.fetch(:status)
    initial_status = status == :closed ? :open : status
    election = Election.create!(title:, status: initial_status)

    scenario.fetch(:results).each do |candidate_name, vote_count|
      candidacy = Candidacy.create!(
        election:,
        candidate: candidates.fetch(candidate_name)
      )

      vote_count.times do
        candidacy.votes.create!(
          submission_id: SecureRandom.uuid,
          submitted_at: Time.current
        )
      end
    end

    election.closed! if status == :closed
  end
end
