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

  test "accepts a JSON vote without a CSRF token" do
    election = elections(:open)
    candidacy = candidacies(:open_maria)
    original_forgery_protection = ActionController::Base.allow_forgery_protection

    ActionController::Base.allow_forgery_protection = true

    travel_to Time.zone.local(2026, 8, 5, 15) do
      assert_enqueued_with(job: RegisterVoteJob, args: [ election.id.to_s, candidacy.id, Time.current ]) do
        post election_votes_url(election),
          params: { vote: { candidacy_id: candidacy.id } },
          as: :json
      end
    end

    assert_response :accepted
    assert_equal({ "message" => "Voto registrado com sucesso." }, response.parsed_body)
  ensure
    ActionController::Base.allow_forgery_protection = original_forgery_protection
  end

  test "enqueues a JSON vote without a candidacy for the job to discard" do
    travel_to Time.zone.local(2026, 8, 5, 15) do
      assert_enqueued_with(job: RegisterVoteJob, args: [ elections(:open).id.to_s, nil, Time.current ]) do
        post election_votes_url(elections(:open)), params: { vote: {} }, as: :json
      end
    end

    assert_response :accepted
  end

  test "enqueues a JSON vote for an unknown candidacy for the job to discard" do
    election = elections(:open)

    travel_to Time.zone.local(2026, 8, 5, 15) do
      assert_enqueued_with(job: RegisterVoteJob, args: [ election.id.to_s, -1, Time.current ]) do
        post election_votes_url(election), params: { vote: { candidacy_id: -1 } }, as: :json
      end
    end

    assert_response :accepted
  end

  test "enqueues a JSON vote for a candidacy from another election for the job to discard" do
    election = elections(:open)
    candidacy = candidacies(:second_open_joao)

    travel_to Time.zone.local(2026, 8, 5, 15) do
      assert_enqueued_with(job: RegisterVoteJob, args: [ election.id.to_s, candidacy.id, Time.current ]) do
        post election_votes_url(election), params: { vote: { candidacy_id: candidacy.id } }, as: :json
      end
    end

    assert_response :accepted
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
