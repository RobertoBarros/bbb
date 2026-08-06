require "test_helper"

class ElectionTest < ActiveSupport::TestCase
  test "defaults to pending" do
    election = Election.create!(title: "Board election")

    assert_predicate election, :pending?
    assert_equal "pending", election.reload.status
    assert_nil election.opened_at
    assert_nil election.closed_at
  end

  test "records the voting window while advancing statuses" do
    election = elections(:pending)

    travel_to Time.zone.local(2026, 8, 5, 10) do
      election.open!

      assert_predicate election, :open?
      assert_equal Time.current, election.opened_at
      assert_nil election.closed_at
    end

    travel_to Time.zone.local(2026, 8, 5, 18) do
      election.closed!

      assert_predicate election, :closed?
      assert_equal Time.current, election.closed_at
    end
  end

  test "does not allow an election to reopen" do
    election = elections(:closed)

    assert_not election.update(status: :open)
    assert_includes election.errors[:status], "não pode mudar de closed para open"
  end
end
