import scala.io.Source
import math.Ordering.Implicits.seqOrdering

/** Data structs
  */
enum HandType(val strength: Int) extends Comparable[HandType]:
  case FIVEOAK extends HandType(7)
  case FOUROAK extends HandType(6)
  case FULLHOUSE extends HandType(5)
  case THREEOAK extends HandType(4)
  case TWOP extends HandType(3)
  case ONEP extends HandType(2)
  case HIGHC extends HandType(1)

  override def compareTo(o: HandType): Int = {
    strength.compareTo(o.strength)
  }
end HandType

case class Hand(cards: Seq[Card], bid: Int)

case class Card(str: String)

/** Problem-specific logic
  */

def handTypePt1(hand: Hand): HandType = {
  import HandType._

  val grouped = hand.cards.groupBy(_.str)
  val sorted = grouped.toList.sortBy(v => -v._2.size)

  if (sorted(0)._2.size == 5) {
    FIVEOAK
  } else if (sorted(0)._2.size == 4) {
    FOUROAK
  } else if (sorted(0)._2.size == 3 && sorted(1)._2.size == 2) {
    FULLHOUSE
  } else if (sorted(0)._2.size == 3) {
    THREEOAK
  } else if (sorted(0)._2.size == 2 && sorted(1)._2.size == 2) {
    TWOP
  } else if (sorted(0)._2.size == 2) {
    ONEP
  } else {
    HIGHC
  }
}

def handTypePt2(hand: Hand): HandType = {
  import HandType._

  val grouped = hand.cards.groupBy(_.str)
  val jokers = grouped.getOrElse("J", Seq()).size
  val sortedCardCounts = grouped
    .filter(_._1 != "J")
    .toList
    .sortBy(v => -v._2.size)
    .map(_._2.size)

  def canMakeFullHouse() = {
    // You can make a full house if you have 2 pairs and 1 J, 1 pair and 2 J, or 0 pairs and 4 J
    // 11222 natural
    // 1122J 1J (needs 2P)
    // 112JJ or 1J22J (2J and 1P)
    (sortedCardCounts(0) == 3 && sortedCardCounts(1) == 2) ||
    (sortedCardCounts(0) == 2 && sortedCardCounts(1) == 2 && jokers == 1) ||
    (sortedCardCounts(0) == 2 && jokers >= 2)
  }

  if (jokers == 5 || sortedCardCounts(0) + jokers == 5) {
    FIVEOAK
  } else if (sortedCardCounts(0) + jokers == 4) {
    FOUROAK
  } else if (canMakeFullHouse()) {
    FULLHOUSE
  } else if (sortedCardCounts(0) + jokers == 3) {
    THREEOAK
  } else if (
    (sortedCardCounts(0) == 2 && sortedCardCounts(1) == 2) || (sortedCardCounts(
      0
    ) == 2 && jokers >= 1)
  ) {
    TWOP
  } else if (sortedCardCounts(0) == 2 || jokers == 1) {
    ONEP
  } else {
    HIGHC
  }
}

/** Main functional driver
  */
def gameSetRanker(
    cardStrengths: (String) => Int,
    fortuneTeller: Hand => HandType // Hand reader
)(hands: Seq[Hand]): Seq[Hand] = {
  hands
    .groupBy(fortuneTeller)
    .toSeq
    .sortBy(_._1)
    .flatMap {
      case (handType, hands) => {
        hands.sortBy(x => (x.cards.map(c => cardStrengths(c.str))))
      }
    }
}

object main extends App {
  def loadHands(fname: String): Seq[Hand] = {
    Source
      .fromFile(fname)
      .getLines()
      .toList
      .map(s => s.split(" "))
      .map(x => Hand(x(0).split("").map(Card.apply), x(1).toInt))
  }

  val part1CardStrengths = (Map(
    "A" -> 14,
    "K" -> 13,
    "Q" -> 12,
    "J" -> 11,
    "T" -> 10
  ) ++ (2 until 10)
    .map(v => (v.toString, v))
    .toMap)

  // Part 2 just pushes "J" to the bottom "T" being 10 is fine since the Int cards are 2->9
  val part2CardStrengths = part1CardStrengths.updated("J", 1)

  // Driver
  // Part-specific params
  val ranker = gameSetRanker(part1CardStrengths, handTypePt1)
  val fname = "day7.input"

  val scores = for {
    (hand, rank) <- ranker(loadHands(fname)).zipWithIndex
    score <- Some((rank + 1) * hand.bid)
  } yield (score)

  // Print answer
  println(scores.sum)
}
