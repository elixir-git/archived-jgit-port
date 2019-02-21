# The first call to register_name/2 is expensive and can cause timeout failures
# in individual tests. Doing it first primes the pump.
Swarm.register_name(make_ref(), self())

ExUnit.start()
