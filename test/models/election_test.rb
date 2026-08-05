require "test_helper"

class ElectionTest < ActiveSupport::TestCase
  test "defaults to pending" do
    election = Election.create!(title: "Board election")

    assert_predicate election, :pending?
    assert_equal "pending", election.reload.status
  end

  test "supports pending, open, and closed statuses" do
    election = elections(:pending)

    election.open!
    assert_predicate election, :open?

    election.closed!
    assert_predicate election, :closed?
  end
end
