require "../spec_helper"

describe Crest::Resource do
  describe "#initialize" do
    it "initialize new resource" do
      resource = Crest::Resource.new("http://localhost", {"X-Something" => "1"})

      resource.url.should eq("http://localhost")
      resource.headers.should eq({"X-Something" => "1"})
    end
  end
end