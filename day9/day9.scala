import scala.io.Source
case class History(values: Seq[Int])

object History {
  def fromString(str: String): History = {
    History(str.split(" ").map(_.toInt))
  }
}

object day9 extends App {

  val fname = "day9.input"
  val histories: Seq[History] = {
    Source.fromFile(fname).getLines().map(History.fromString).toSeq
  }

  def rollout(history: History): Seq[History] = {
    var result: Seq[History] = Seq(history)
    while (!result.head.values.forall(_ == 0)) {
      result = delta(result.head) +: result
    }
    result
  }

  def delta(history: History): History = {
    History(
      history.values
        .scanLeft((0, 0)) { case ((diff, last), v) =>
          (v - last, v)
        }
        .drop(2)
        .map(_._1)
    )
  }

  def rollup(histories: Seq[History]): Int = {
    histories
      .scanLeft(0) { case (sum, history) =>
        sum + history.values.last
      }
      .last
  }

  // Part 1
  def part1Agg(sum: Int, history: History): Int = {
    (sum + history.values.last)
  }

  println(
    f"Part 1: ${histories.map(rollout).map(histories => histories.scanLeft(0)(part1Agg).last).sum}"
  )

  // Part 2
  def part2Agg(sum: Int, history: History): Int = {
    -(sum - history.values.head)
  }

  println(s"Part 2: ${histories
      .map(rollout)
      .map(histories => histories.scanLeft(0)(part2Agg).last)
      .sum}")
}
