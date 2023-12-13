import scala.io.Source
import scala.collection.mutable

case class Node(label: String, var left: String = "", var right: String = "")

object day8 extends App {

  /** Helpers */
  def parseInput(fname: String): (Seq[String], Map[String, Node]) = {
    // Returns (AAA, all nodes)
    val lines = Source.fromFile(fname).getLines().toIterator
    val first = lines.next()
    lines.next()

    val instructions: Seq[String] = first.split("")

    val nodeMap = mutable.Map[String, Node]()

    def parseLine(line: String): (String, String, String) = {
      val lhs = line.split("=")(0).trim().strip()
      val rhs = line.split("=")(1)

      val rhs_cleaned = rhs.replace("(", "").replace(")", "").split(", ")
      val left = rhs_cleaned(0).trim().strip()
      val right = rhs_cleaned(1).trim().strip()

      (lhs, left, right)
    }

    lines
      .map(parseLine)
      .foreach { case (lhs, left, right) =>
        nodeMap.update(lhs, Node(lhs, left, right))
      }

    (instructions, nodeMap.toMap)
  }

  def run(
      node: Node,
      instructions: Seq[String],
      stopCriterion: String => Boolean,
      nodes: Map[String, Node]
  ): Iterator[(Int, String)] = {
    Iterator
      .continually(instructions)
      .flatten
      .scanLeft((0, node.label)) {
        case (pair, "L") => (pair._1 + 1, nodes(pair._2).left)
        case (pair, "R") => (pair._1 + 1, nodes(pair._2).right)
      }
      .dropWhile { case (_, node) => !stopCriterion(node) }
  }

  def part1(instructions: Seq[String], nodes: Map[String, Node]) = {
    println(
      run(
        nodes("AAA"),
        instructions,
        _ == "ZZZ",
        nodes
      ).next()
    )
  }

  def part2(instructions: Seq[String], nodes: Map[String, Node]) = {
    // Find all start nodes
    val startNodes = nodes.keys.filter(v => v.last.toString() == "A").toSeq
    var cycleLengths = startNodes
      .map(nodes)
      .map(nodeLabel => run(nodeLabel, instructions, _.last == 'Z', nodes))
      .map(_.next()._1)
      .toVector

    // Find prime factors
    def factorize(i: Int, factors: Vector[Int] = Vector()): Vector[Int] = {
      if (i == 1) {
        factors
      } else {
        val f = (2 to i).find(i % _ == 0).getOrElse(i)
        factorize(i / f, factors :+ f)
      }
    }

    val factorized = cycleLengths.map(i => factorize(i))

    println(
      factorized
        .map(_.map(_.toLong))
        .map(_.groupBy(identity))
        .flatMap(_.toSeq.map(kv => (kv._1, kv._2.size)))
        .sortBy(_._1)
        .groupBy(_._1)
        .map { case (base, powers) => powers.sortBy(_._2).last }
        .toSeq
        .sortBy(_._1)
        .scanLeft(BigInt(1)) {
          case (product, (base, power)) => (
            product * BigInt(Math.pow(base, power).toLong)
          )
        }
        .last
    )
  }

  /** Driver */
  val input = "day8.input"
  val parsed = parseInput(input)

  val instructions = parsed._1
  val nodes = parsed._2

  part1(instructions, nodes)
  part2(instructions, nodes)

  /** Driver */
}
