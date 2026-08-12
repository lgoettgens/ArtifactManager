return [
  rec(
    name := "bad",
    tree_sha256 := "not-a-valid-sha256-hash",
    lazy := true,
    downloads := [
      rec(
        url := "https://example.org/data/bad.tar.gz",
        sha256 := "2222222222222222222222222222222222222222222222222222222222222222"
      )
    ]
  )
];
