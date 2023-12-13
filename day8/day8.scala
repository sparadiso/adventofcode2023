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
    val solveOnce = label => run(label, instructions, _.last == 'Z', nodes)

    // Find each path length to *Z in parallel
    var cycleLengths = startNodes
      .map(nodes)
      .map(solveOnce)
      .map(_.next())
      .map(_._1)
      .toVector

    // Find least common multiple between all paths / prime factor method
    // Find prime factors
    def factorize(i: Int, factors: Vector[Int] = Vector()): Vector[Int] = {
      if (i == 1) {
        factors
      } else {
        val f = (2 to i).find(i % _ == 0).getOrElse(i)
        factorize(i / f, factors :+ f)
      }
    }

    val factorized = cycleLengths.map(i => factorize(i)).map(_.map(_.toLong))

    println(
      factorized
        .map(_.groupBy(identity).toSeq)
        .flatMap( // Map prime factors to powers
          _.map((base, factors) => (base, factors.size))
        )
        .groupBy(_._1) // Collect all cycle length's prime factors
        .map {
          case (base, powers) => // Find the largest power of each prime factor
            powers.sortBy(_._2).last
        }
        .scanLeft(1L) { // product of all the largest prime factor powers = lcm
          case (product, (base, power)) =>
            product * Math.pow(base, power).toLong
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
