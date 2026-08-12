return [
  rec(
    name := "s",
    tree_sha256 := "1111111111111111111111111111111111111111111111111111111111111111",
    lazy := true,
    downloads := [
      rec(
        url := "https://example.org/data/s.tar.gz"
      )
    ]
  )
];
