#include <benchmark/benchmark.h>
#include <example/lib/a.hpp>

static void BM_SomeFunction(benchmark::State &state)
{
  // Perform setup here
  for (auto _ : state)
  {
    a();
  }
}
// Register the function as a benchmark
BENCHMARK(BM_SomeFunction);