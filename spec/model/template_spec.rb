describe "HTML Template" do
  it "render html" do
    source = "<div>{% foo %}</div>"
    template = Template.new(source)
    html = template.render( "foo" => "<bar" )
    html.should == "<div>&lt;bar</div>"
  end
  it "loop" do
    source = "<ul>{% FOR items %}<li>{% body %}{% apple %}</li>{% END %}</ul>"
    template = Template.new(source)
    html = template.render( "items" => [ { "body" => "hoge"}, { "body" => "fuga" } ] )
    html.should == "<ul><li>hoge</li><li>fuga</li></ul>"
  end
end
