import scala.io.Source
import java.io.File

case class Race(time: BigDecimal, distance: BigDecimal) 

def distance(timeHeld: BigInt, raceTime: BigInt, acceleration: BigInt = 1): BigInt = {
    acceleration * timeHeld * (raceTime - timeHeld)
}

def parseInput(fname: String): Seq[Race] = {
    val lines = Source
        .fromFile(fname)
        .getLines()
        .map(_.split(" ").toList.filter(_.toIntOption.isDefined))
        .map(_.map(BigDecimal.apply))
        .toList
    
    lines(0).zip(lines(1)).map(Race.apply)
}

def parseInputPt2(fname: String): Race = {
    val lines = Source
        .fromFile(fname)
        .getLines()
        .map(_.split(":")(1).replace(" ", ""))
        .map(BigDecimal.apply)
        .toList

    Race(lines(0), lines(1))
}

def zeros(race: Race): (BigDecimal, BigDecimal) = {
    ((race.time - Math.sqrt((race.time*race.time - 4.0 * race.distance).toDouble))/2.0,
        (race.time + Math.sqrt((race.time*race.time - 4.0 * race.distance).toDouble))/2.0
    )
}

object main extends App {
    val races = parseInputPt2("day6.input")
    val t: (BigDecimal, BigDecimal) = zeros(races)
    println(t._2.toBigInt - t._1.toBigInt)
}