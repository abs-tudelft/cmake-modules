#include <gtest/gtest.h>
#include <example/lib/b.hpp>
#include <example/lib/c.hpp>

TEST(c, unit) {
  b();
  c();
  ASSERT_EQ(2 + 2, 4);
}
