return [
  rec(
    name := "brent-table-1000",
    tree_sha256 := "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    lazy := true,
    downloads := [
      rec(
        url := "https://example.org/data/brent-table-1000.tar.gz",
        sha256 := "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
      ),
      rec(
        url := "https://mirror.example.org/data/brent-table-1000.tar.gz",
        sha256 := "fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210"
      )
    ]
  ),
  rec(
    name := "brent-table-2000",
    tree_sha256 := "1111111111111111111111111111111111111111111111111111111111111111",
    lazy := true,
    downloads := [
      rec(
        url := "https://example.org/data/brent-table-2000.tar.gz",
        sha256 := "2222222222222222222222222222222222222222222222222222222222222222"
      )
    ]
  )
];
