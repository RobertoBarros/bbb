require "test_helper"

class VotesControllerTest < ActionDispatch::IntegrationTest
  test "enqueues a vote without persisting it and redirects to home" do
    election = elections(:open)
    candidacy = candidacies(:open_maria)

    travel_to Time.zone.local(2026, 8, 5, 15) do
      assert_no_difference "Vote.count" do
        assert_enqueued_with(
          job: RegisterVoteJob,
          args: [ election.id.to_s, candidacy.id.to_s, Time.current ],
          queue: "votes"
        ) do
          post election_votes_url(election), params: { vote: { candidacy_id: candidacy.id } }
        end
      end
    end

    assert_redirected_to root_url
    assert_equal "Voto registrado com sucesso.", flash[:notice]

    follow_redirect!
    assert_select "[data-flash='notice']", "Voto registrado com sucesso."
  end

  test "enqueues missing identifiers for the job to discard" do
    travel_to Time.zone.local(2026, 8, 5, 15) do
      assert_enqueued_with(job: RegisterVoteJob, args: [ elections(:open).id.to_s, nil, Time.current ]) do
        post election_votes_url(elections(:open)), params: { vote: {} }
      end
    end

    assert_redirected_to root_url
  end

  test "enqueues each repeated anonymous submission" do
    election = elections(:open)
    candidacy = candidacies(:open_maria)

    assert_no_difference "Vote.count" do
      assert_enqueued_jobs 2, only: RegisterVoteJob do
        2.times do
          post election_votes_url(election), params: { vote: { candidacy_id: candidacy.id } }
        end
      end
    end
  end
end
