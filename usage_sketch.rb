# we have two objects [obj1, obj2] with predicate methods

@registered_req = AttachListen::Requirement.to_be(
    obj1.method(:in_desired_state1?),
    obj2.method(:in_desired_state2?).tap do |req|
  req.when_met { ... do something ... }
  req.when_unmet { ... do something else ... }
  req.on_exception { |exception, occasion| ... inform the police ... }

  # with the setup so far, after the final connect, whe when_met/when_unmet would be called
  # exactly when the ANDed conditions _become_ true/false.

  # If we do this in addition:
  req.treat_disconnected_as_unmet!
  # then in addition
  # * the when_met block is called at connect time if ANDed conditions are true then
  # * then when_unmet block is called at disconnect time if ANDed conditions are true then
end.connect

...

@registered_req.disconnect
@registered_req = nil


# How to treat intermediate failure (e.g. exceptions in when_met block):
@setup_in_met = false
@registered_req = AttachListen::Requirement.to_be(obj1.method(:in_desired_state1?),
    obj2.method(:in_desired_state2?).tap do |req|
  req.when_met do
    unless @setup_in_met
      ...
      @setup_in_met = true
    end
  end
  req.when_unmet do
    if @setup_in_met
      ...
      @setup_in_met = false
    end
  end

  req.treat_disconnected_as_unmet!
end.connect
# Do we want more sugar for this case? What would that look like?

# Sugar variant
@setup_in_met = false
@registered_req = AttachListen::Requirement.to_be(obj1.method(:in_desired_state1?),
    obj2.method(:in_desired_state2?).tap do |req|
  req.when_met do
    unless @setup_in_met
      ...
      @setup_in_met = true
    end
  end
  req.when_unmet do
    if @setup_in_met
      ...
      @setup_in_met = false
    end
  end

  req.stateful! #implies .treat_disconnected_as_unmet

  #now we are stateful, we can
  req.refined_to_be(obj3.method(:in_desired_stage)).tap do |ref_req|
    ...
  end.connect
  #which is roughly equivalent to:
  AttachListen::Requirement.to_be(req.state,obj3.method(:in_desired_stage)).tap do |ref_req|
    ...
  end.connect

end.connect

# How we can hide complex logic:

machine = AttachListen::Machine.from_inputs(obj1.method(:parent)) #or

machine = AttachListen::Machine.from_inputs(:master_parent => obj1.method(:parent), :app_state => obj2.method(:state)) do |mac|
  @inner_state_var = 0 #we're inside an object this time

  #access to state:
  master_parent_value
  app_state_value

  # ... heavy calculation ...

  become(bool)

  on_master_parent_change do |new_value|
    # ... heavy calculation ...
    become_true
    become_false
    become(bool)
  end

  # ...
end

# I actually want to get rid of the .connect stuff.

@registered_req = AttachListen::Requirement.to_be(obj1.method(:in_desired_state1?),
    obj2.method(:in_desired_state2?) do |req|
  req.when_met { ... do something ... }
  req.when_unmet { ... do something else ... }
  req.on_exception { |which| ... inform the police ... }

  req.treat_disconnected_as_unmet!
  req.dispatch_with(dispatcher) #??
end

@registered_req.disconnect
@registered_req.connect

# state local configuration:

AttachListen.configured do |config|
  config.treat_disconnected_as_unmet!
  config.on_exception { |exception| ... }
end
