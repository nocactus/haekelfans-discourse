import { module, test } from "qunit";
import { generateTitle } from "../../discourse/lib/hf-composer";

module("Häkelfans | Unit | generateTitle", function () {
  test("pakt de eerste 8 woorden zonder links", function (assert) {
    assert.strictEqual(
      generateTitle(
        "Schau mal https://x.de dieses tolle Garn das ich gefunden habe heute"
      ),
      "Schau mal dieses tolle Garn das ich gefunden"
    );
  });

  test("kapt af op 60 tekens zonder half woord", function (assert) {
    const title = generateTitle(
      "Wunderschönes selbstgemachtes Riesenprojekt außergewöhnlicher Handarbeitskunst verzaubert alle Betrachterinnen restlos"
    );
    assert.true(title.length <= 60);
    assert.false(title.endsWith(" "));
  });

  test("leeg blijft leeg", function (assert) {
    assert.strictEqual(generateTitle(""), "");
  });
});
