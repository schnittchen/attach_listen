# we have three objects [obj1, obj2, obj3] with predicate methods

@registered_req = AttachListen::Requirement.to_be(
    obj1.method(:in_desired_state1?),
    obj2.method(:in_desired_state2?) do |req|
  req.when_met { ... do something ... }
  req.when_unmet { ... do something else ... }
  req.instrument do |req, occasion, &block| #block is when_met/when_unmet block
    # possibly log, meature time, ...
    # some provision (yet to be invented) gives you interesting infos on req for debugging
    block.call
    # catch exception if you want (won't bubble up anyway)
  end

  # with the setup so far, after the final connect, whe when_met/when_unmet would be called
  # exactly when the ANDed conditions _become_ true/false.

  #we have several modes:

  req.mode :evented
  #this is the default. when_met/when_unmet blocks are called when the requirement becomes met/unmet.

  req.mode :evented_plus #sorry for the name.
  #same as above, plus:
  # * if the requirement is already met at connect time, when_met block is called
  # * if the requirement is met, when_unmet is called on .disconnect

  req.mode :stateful
  #in short, when_met and when_unmet behave like construction/tear down.
  #
  #requirement is only considered to be met when all dependent conditions are true and when_met block
  #has been called successfully.
  #when the first condition becomes false or on .disconnect,
  #when_unmet block is NOT called unless requirement is in met state.
  #The requirement provides its state as an attachable predicate, so you can nest requirements for refinement.


  req.dispatch_with(dispatcher) # ??

end # <- connection is established after config block is left

@registered_req.disconnect #detach from providers. help your garbage collector!


# Stateful example with refinement
@registered_req = AttachListen::Requirement.to_be(obj1.method(:in_desired_state1?),
    obj2.method(:in_desired_state2?) do |req|
  req.when_met do
      ...
  end
  req.when_unmet do
      ...
  end
  req.mode :stateful

  #sugar variant
  req.refined_to_be(obj3.method(:in_desired_stage)) do |ref_req|
    ...
  end

  #which is roughly equivalent to:
  AttachListen::Requirement.to_be(req.method(:state), obj3.method(:in_desired_stage)).tap do |ref_req|
    ref_req.mode :stateful
    ...
  end.connect

end.connect

# How we can hide complex logic:

machine = AttachListen::Machine.from_inputs(obj1.method(:parent)) do
  provider_value
end

machine = AttachListen::Machine.from_inputs(:master_parent => obj1.method(:parent), :app_state => obj2.method(:state)) do
  @inner_state_var = 0 #we're inside an object this time

  #access to state:
  master_parent_value
  app_state_value

  # ... heavy calculation ...

  #initial state
  become(bool)

  on_master_parent_change do |new_value|
    # ... heavy calculation ...

    #publish state change
    become_true
    become_false
    become(bool)
  end

  # ...
end

#easier configuration:

AttachListen.requirement_configuration(:token) do |config|
  config.mode :stateful

  config.treat_disconnected_as_unmet!

  config.instrument { ... }
end

AttachListen::Requirement.to_be(..., :config => :token) { ... }
