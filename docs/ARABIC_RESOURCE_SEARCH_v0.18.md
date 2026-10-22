# PalEdu v0.18 — Arabic resource library search

The in-app published library now performs **local multi-word Arabic matching**
across approved resource titles and subject labels. Search strips tashkeel and
tatweel and recognizes common alef/yaa/taa marbuta spelling variants and
contracted Arabic definite articles (e.g. للأعداد / الأعداد).

The existing grade, Tawjihi track, semester, resource-type and private
per-account favourite filters remain active. Search only narrows the resources
that the existing authenticated published-library query already returned.

## Privacy and licensing

- No queries sent by this feature to an analytics or search provider.
- No indexing of signed Supabase storage URLs, access tokens, private user IDs
  or document bodies.
- No files cached for offline use or rehosted. Published-resource metadata
  can be searched locally after the current library request succeeds; a live
  configured backend is still needed to fetch remote resources.
- No claim that Palestinian textbook content is fully uploaded/licensed or that
  large-scale capacity has been load-tested.

## Validation

Run Flutter static analysis and the full test suite (including
`test/resource_search_test.dart`), Android debug APK, Web build and
security/curriculum workflows on the same pull request head before merge.
