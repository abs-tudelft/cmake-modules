#include <benchmark/benchmark.h>
#include <example/lib/interface.hpp>

static void BM_SomeFunction(benchmark::State &state)
{
  // Perform setup here
  for (auto _ : state)
  {
    interface();
  }
}
// Register the function as a benchmark
BENCHMARK(BM_SomeFunction);