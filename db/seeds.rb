candidate_names = [
  "João da Silva",
  "Maria de Oliveira",
  "José dos Santos",
  "Ana Souza",
  "Carlos Pereira",
  "Francisca Almeida"
]

candidates = candidate_names.index_with do |name|
  Candidate.find_or_create_by!(name:)
end

scenarios = {
  "votação da semana 1" => {
    "João da Silva" => 8,
    "Maria de Oliveira" => 5,
    "José dos Santos" => 2
  },
  "votação da semana 2" => {
    "Ana Souza" => 4,
    "Carlos Pereira" => 4,
    "João da Silva" => 1
  },
  "votação da semana 3" => {
    "Maria de Oliveira" => 0,
    "José dos Santos" => 0,
    "Francisca Almeida" => 0
  }
}

scenarios.each do |title, results|
  election = Election.find_or_create_by!(title:)

  results.each do |candidate_name, expected_votes|
    candidacy = Candidacy.find_or_create_by!(
      election:,
      candidate: candidates.fetch(candidate_name)
    )

    (expected_votes - candidacy.votes.count).times do
      candidacy.votes.create!
    end
  end
end
