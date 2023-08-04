require "rails_helper"
require "shared_examples"
include SessionsHelper

RSpec.describe Supervisor::StaticPagesController, type: :controller do
  describe "GET home" do
    it_behaves_like "requires supervisor", :home
  end
end
