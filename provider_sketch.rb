class SomeClass
  include AttachListen::Provider

  attachable_state :some_state
  attachable_predicate :set_up?
end
