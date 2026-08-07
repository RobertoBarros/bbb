require "test_helper"

class VotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActionController::Base.cache_store.clear
  end

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

  test "limits vote requests from the same IP" do
    election = elections(:open)
    candidacy = candidacies(:open_maria)
    headers = { "REMOTE_ADDR" => "192.0.2.1" }

    assert_enqueued_jobs 5, only: RegisterVoteJob do
      5.times do
        post election_votes_url(election), params: { vote: { candidacy_id: candidacy.id } }, headers: headers
        assert_response :redirect
      end
    end

    assert_no_enqueued_jobs only: RegisterVoteJob do
      post election_votes_url(election), params: { vote: { candidacy_id: candidacy.id } }, headers: headers
    end

    assert_response :too_many_requests
  end

  test "allows vote requests from a different IP after a rate limit" do
    election = elections(:open)
    candidacy = candidacies(:open_maria)

    6.times do
      post election_votes_url(election),
        params: { vote: { candidacy_id: candidacy.id } },
        headers: { "REMOTE_ADDR" => "192.0.2.1" }
    end

    assert_response :too_many_requests

    assert_enqueued_jobs 1, only: RegisterVoteJob do
      post election_votes_url(election),
        params: { vote: { candidacy_id: candidacy.id } },
        headers: { "REMOTE_ADDR" => "192.0.2.2" }
    end

    assert_response :redirect
  end

  test "disables the vote rate limit in load test mode" do
    election = elections(:open)
    candidacy = candidacies(:open_maria)
    original_load_test_mode = ENV["LOAD_TEST_MODE"]
    ENV["LOAD_TEST_MODE"] = "true"

    assert_enqueued_jobs 6, only: RegisterVoteJob do
      6.times do
        post election_votes_url(election),
          params: { vote: { candidacy_id: candidacy.id } },
          headers: { "REMOTE_ADDR" => "192.0.2.1" }
        assert_response :redirect
      end
    end
  ensure
    ENV["LOAD_TEST_MODE"] = original_load_test_mode
  end

  test "keeps the vote rate limit enabled when load test mode is false or invalid" do
    election = elections(:open)
    candidacy = candidacies(:open_maria)
    original_load_test_mode = ENV["LOAD_TEST_MODE"]

    [ "false", "enabled" ].each_with_index do |load_test_mode, index|
      ENV["LOAD_TEST_MODE"] = load_test_mode

      6.times do
        post election_votes_url(election),
          params: { vote: { candidacy_id: candidacy.id } },
          headers: { "REMOTE_ADDR" => "192.0.2.#{index + 1}" }
      end

      assert_response :too_many_requests
    end
  ensure
    ENV["LOAD_TEST_MODE"] = original_load_test_mode
  end
end
