return [
  rec(
    name := "f",
    tree_sha256 := "1111111111111111111111111111111111111111111111111111111111111111",
    lazy := false,
    downloads := [
      rec(
        url := "https://example.org/data/false-lazy.tar.gz",
        sha256 := "2222222222222222222222222222222222222222222222222222222222222222"
      )
    ]
  )
];
