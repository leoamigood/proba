# start the current node as a manager
:ok = LocalCluster.start()

# start your application tree manually
Application.ensure_all_started(:proba)

# run all tests!
LocalCluster.start_nodes("poker-cluster", 2)
ExUnit.start()
:ok = LocalCluster.stop()