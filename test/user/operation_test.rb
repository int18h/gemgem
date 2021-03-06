require 'test_helper'

class UserOperationTest < MiniTest::Spec
  # valid create
  it do
    user = User::Create[
      email: "nick@trailblazerb.org",
    ]

    assert user.id > 0
    assert user.persisted?
  end

  # autocomplete
  it do
    User.delete_all # TODO: use database cleaner.

    user1 = User::Create[email: "nick@trailblazerb.org"]
    User::Create[email: "gonzo@web.de"]
    user3 = User::Create[email: "apotonick@gmail.com"]

    User::Search[term: "no"].must_equal []
    User::Search[term: "ick"].must_equal [
      {value: "#{user1.id}", label: "nick@trailblazerb.org"},
      {value: "#{user3.id}", label: "apotonick@gmail.com"}
    ]
  end

  let (:user) { User::Create[email: "nick@trailblazerb.org"] }
  # confirm account
  it do
    # op = Thing::Create[name: "Trb"]
    # rating = Rating::Create[comment: "Interesting!", weight: 1, thing: {id: op.model.id}, user: {email: "nick@trb.org"}].model

    Monban::ConfirmLater[id: user.id] # set User#confirmation_token. this is sent.
    user.reload
    user.confirmation_token.wont_equal nil

    Monban::IsConfirmationAllowed[id: user.id, confirmation_token: "afsdfa"].must_equal false # in before_filter, policy.
    Monban::IsConfirmationAllowed[id: user.id, confirmation_token: "abc123"].must_equal true

    Monban::Confirm[id: user.id, password: "abc"] # call this from console!
    user.reload
    assert user.password_digest.size > 10

    # Monban::SignIn[]
  end

  # PUBLIC confirm, differing passwords. this happens after IsConfirmationAllowed?
  it do
    res, op = User::Confirm.run(id: user.id, user: {password: "abc", password_confirmation: "bbbbbbb"})
    res.must_equal false
    op.contract.errors.to_s.must_equal "{:password_confirmation=>[\"doesn't match Password\"]}"
  end

  # Confirm valid.
  it do
    op = User::Confirm[id: user.id, user: {password: "abc", password_confirmation: "abc"}]

    assert User.find(user.id).password_digest.size > 10
  end

  # Edit
  # Update
  it "User::Update" do
    User::Update[id: user.id, user: {image: upload}]

    id = user.id
    user = User.find(id)
    user.image_meta_data.must_equal :original=>{:width=>1280, :height=>720, :uid=>"original-vb.jpg"}, :thumb=>{:width=>75, :height=>75, :uid=>"thumb-vb.jpg"}
  end
end

