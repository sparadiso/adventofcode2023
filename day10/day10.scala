import scala.io.Source
import scala.collection.mutable
import scala.util.Try

implicit def toPipe(t: Tile): Pipe = t.asInstanceOf[Pipe]

enum Direction {
  case UP, DOWN, LEFT, RIGHT
}
object Direction {
  def apply(from: Point, to: Point): Direction = {
    if (to.row == from.row) {
      if (to.col > from.col) { RIGHT }
      else { LEFT }
    } else {
      if (to.row > from.row) { DOWN }
      else UP
    }
  }
}

trait Tile {
  var label: String
  var visited: Boolean = false
  val pt: Point
}

case class Ember(loc: Pipe, distance: Int = 0)
case class Point(row: Int, col: Int)
case class Dot(var label: String, pt: Point) extends Tile
case class Pipe(var label: String, neighbors: (Point, Point), pt: Point)
    extends Tile

case class Grid(start: Point, tiles: Vector[Vector[Tile]]) {
  def apply(p: Point): Tile = {
    tiles(p.row)(p.col)
  }
}

object Grid {
  def apply(str: Seq[Seq[String]]): Grid = {

    var start: Point = null
    val tiles = str.zipWithIndex.map { (row, rowIdx) =>
      row.zipWithIndex.map { (col, colIdx) =>
        col match {
          case "." => Dot(col, Point(rowIdx, colIdx))
          case "S" =>
            start = Point(rowIdx, colIdx)

            // Infer the neighbors
            var neighbors = List[Point]()
            var r = rowIdx
            var c = colIdx
            List(
              ((0, -1), Set("-", "L", "F")),
              ((0, 1), Set("-", "J", "7")),
              ((-1, 0), Set("|", "F", "7")),
              ((1, 0), Set("|", "J", "L"))
            ).foreach { case (dr, m) =>
              val t = str(r + dr._1)(c + dr._2)
              if (m.contains(t)) {
                neighbors = neighbors :+ Point(r + dr._1, c + dr._2)
              }
            }

            assert(
              neighbors.size == 2,
              f"Uh, why are there not 2 S neighbors (${neighbors})"
            )

            Pipe(col, (neighbors(0), neighbors(1)), Point(rowIdx, colIdx))

          case "|" =>
            Pipe(
              col,
              (Point(rowIdx - 1, colIdx), Point(rowIdx + 1, colIdx)),
              Point(rowIdx, colIdx)
            )
          case "-" =>
            Pipe(
              col,
              (Point(rowIdx, colIdx - 1), Point(rowIdx, colIdx + 1)),
              Point(rowIdx, colIdx)
            )
          case "J" =>
            Pipe(
              col,
              (Point(rowIdx, colIdx - 1), Point(rowIdx - 1, colIdx)),
              Point(rowIdx, colIdx)
            )
          case "F" =>
            Pipe(
              col,
              (Point(rowIdx + 1, colIdx), Point(rowIdx, colIdx + 1)),
              Point(rowIdx, colIdx)
            )
          case "7" =>
            Pipe(
              col,
              (Point(rowIdx, colIdx - 1), Point(rowIdx + 1, colIdx)),
              Point(rowIdx, colIdx)
            )
          case "L" =>
            Pipe(
              col,
              (Point(rowIdx - 1, colIdx), Point(rowIdx, colIdx + 1)),
              Point(rowIdx, colIdx)
            )
        }
      }.toVector
    }.toVector

    Grid(start, tiles)
  }
}

def burnDots(pt: Point, grid: Grid, loopPipes: Set[Point]): Unit = {
  if (Try(grid(pt)).isSuccess && !grid(pt).visited) {
    grid(pt) match {
      case x: Tile if !loopPipes.contains(x.pt) =>
        x.visited = true
        burnDots(Point(pt.row - 1, pt.col), grid, loopPipes)
        burnDots(Point(pt.row + 1, pt.col), grid, loopPipes)
        burnDots(Point(pt.row, pt.col - 1), grid, loopPipes)
        burnDots(Point(pt.row, pt.col + 1), grid, loopPipes)
      case _ =>
    }
  }
}

def pipeLoop(grid: Grid): Seq[Pipe] = {
  var pipeLoop = { Seq(startPoints(grid.start, grid): _*) }.take(1)
  grid(grid.start).visited = true
  pipeLoop.foreach(_.loc.visited = true)

  var active = pipeLoop
  while (active.size > 0) {
    active = burn(active, grid)
    pipeLoop = pipeLoop.appendedAll(active)
  }

  pipeLoop.map(_.loc)
}

def part1(fname: String): Int = {
  var grid = Grid(
    Source.fromFile(fname).getLines().map(_.split("").toList).toList
  )

  grid(grid.start).visited = true

  var embers: Seq[Ember] = { Seq(startPoints(grid.start, grid): _*) }
  embers.foreach(_.loc.visited = true)

  var last = Seq[Ember]()
  while (embers.size > 0) {
    last = embers
    embers = burn(embers, grid)
  }

  last.sortBy(_.distance).last.distance + 1
}

def part2(fname: String): Int = {
  val grid = Grid(
    Source
      .fromFile(fname)
      .getLines()
      .map(_.split("").toList)
      .toList
  )

  def isDot(t: Tile, loopPipes: Set[Point]): Boolean = {
    (!loopPipes.contains(t.pt)) || t.isInstanceOf[Dot]
  }

  // Figure out what S is
  val n = grid(grid.start).neighbors.toList
    .map(p => Point(p._1 - grid.start.row, p._2 - grid.start.col))
    .toSet

  val sPipe = n match {
    case x if x == Set(Point(-1, 0), Point(1, 0))  => "|"
    case x if x == Set(Point(0, -1), Point(0, 1))  => "-"
    case x if x == Set(Point(0, -1), Point(-1, 0)) => "J"
    case x if x == Set(Point(-1, 0), Point(0, 1))  => "L"
    case x if x == Set(Point(0, -1), Point(1, 0))  => "7"
    case x if x == Set(Point(0, 1), Point(1, 0))   => "F"
  }

  // Get the pipes
  val loop = pipeLoop(grid)
  val pipeSet = loop.map(_.pt).toSet + grid.start

  var count = 0
  grid.tiles.foreach { row =>
    var interior = false

    row.foreach { tile =>
      if (pipeSet.contains(tile.pt)) {
        var lbl = tile.label
        if (lbl == "S") {
          lbl = sPipe
        }
        lbl match {
          case "|" | "J" | "L" => interior = !interior
          case _               =>
        }
      } else {
        if (isDot(tile, pipeSet) && interior) {
          count += 1
        }
      }
    }
  }

  count
}

def startPoints(start: Point, grid: Grid): Seq[Ember] = {

  // check up down left right
  val pts = List(
    grid.tiles(start.row - 1)(start.col).label match {
      case "|" | "7" | "F" =>
        Try(Ember(grid(Point(start.row - 1, start.col)))).toOption
      case _ => None
    },
    grid.tiles(start.row)(start.col - 1).label match {
      case "-" | "L" | "F" =>
        Try(Ember(grid(Point(start.row, start.col - 1)))).toOption
      case _ => None
    },
    grid.tiles(start.row)(start.col + 1).label match {
      case "-" | "J" | "7" =>
        Try(Ember(grid(Point(start.row, start.col + 1)))).toOption
      case _ => None
    },
    grid.tiles(start.row + 1)(start.col).label match {
      case "|" | "J" | "L" =>
        Try(Ember(grid(Point(start.row + 1, start.col)))).toOption
      case _ => None
    }
  ).flatten

  pts
}

def burn(embers: Seq[Ember], grid: Grid): Seq[Ember] = {
  // Take in burning tiles, return the next set of burning tiles
  embers
    .flatMap { ember =>
      val neighbors = grid(ember.loc.pt).neighbors

      var nextPipe: Option[Pipe] = {
        if (!grid(neighbors.head).visited) Option(grid(neighbors.head))
        else if (!grid(neighbors(1)).visited) Option(grid(neighbors(1)))
        else None
      }

      nextPipe.map { p =>
        p.visited = true; Ember(p, ember.distance + 1)
      }
    }
}

object day10 extends App {
  // Part 1
  println(f"Part1 = ${part1("day10.input")}")

  // Part 2
  val pairs = List(
    (part2("day10_test.input"), 3),
    (part2("day10_test2.input"), 4),
    (part2("day10_test3.input"), 10),
    (part2("day10_test4.input"), 8)
  )

  pairs.foreach { case (got, expected) =>
    assert(got == expected, f"Got ${got} expected ${expected}")
  }

  println(f"Part2 = ${part2("day10.input")}")
}
