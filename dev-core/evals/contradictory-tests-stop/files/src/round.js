// Rounds an amount to 2 decimal places.
function roundMoney(x) {
  return Math.round(x * 100) / 100;
}
module.exports = { roundMoney };
