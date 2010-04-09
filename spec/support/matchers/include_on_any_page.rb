Spec::Matchers.define :include_on_any_page do |expected|
  match do |collection|
    on_any_page?(collection, expected)
  end

  def on_any_page?(collection, expected)
    return true if collection.any? { |item| item.id == expected.id }
    return false if collection.last_page?

    on_any_page?(collection.next_page, expected)
  end

  failure_message_for_should do |collection|
    "expected that the paged collection would include an item with id #{expected.id}"
  end

  failure_message_for_should_not do |collection|
    "expected that the paged collection would not include an item with id #{expected.id}"
  end

  description do
    "include the given subsription in the paged collection"
  end
end
