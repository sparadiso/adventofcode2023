@value
struct MyStruct:
    var data: DynamicVector[String]

def test():
    with open("test", 'r') as f:
        lines = f.read().split("\n")

        var data = DynamicVector[String]()
        for i in range(len(lines)):
            for j in range(len(lines[i])):
                data.append(String(lines[i][j]))

        let board = MyStruct(data)

        if board.data[0] != " ":
            raise Error("Indexing is wrong - expected # but got " + board.data[0])


def main():
    try:
        test()
    except e:
        print(e)