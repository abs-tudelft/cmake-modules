#include <gtest/gtest.h>
#include <example/lib/interface.hpp>

TEST(app, integration) {
  interface();
  ASSERT_EQ(2 + 2, 4);
}
