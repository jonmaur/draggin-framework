from rect import Rect


class QuadTree(object):
    def __init__(self, xywh):
        self.rect = Rect(xywh)

    def __repr__(self):
        return "<%s %s>" % (self.__class__.__name__, (self.rect.left, self.rect.bottom, self.rect.right, self.rect.top))

    def query(self, rect):
        """
        Return likely intersections with rect.
        """
        if hasattr(self, 'leaves'):
            return self.leaves.values()
        else:
            results = []
            rect = Rect(rect)
            for c in self.children:
                if c.rect.intersects(rect):
                    results.extend(c.query(rect))
            return set(results)

    def insert(self, id, rect):
        """
        Insert a rect with an id into the index.
        """
        if hasattr(self, 'leaves'):
            self.leaves[rect] = id
        else:
            for c in self.children:
                if c.rect.intersects(rect):
                    c.insert(id, rect)


def index(size, center=(0.0,0.0), depth=5, level=0):
    """
    Build a spatial index using a Quadtree.
    size: width and height of the quadtree
    center: center point of the quadtree
    depth: levels deep to build leaves
    level: ignore this, used internaly.
    """
    level += 1
    if level > depth: return
    x,y = center
    w = size * 0.5
    n = QuadTree((x-w,y-w,size,size))
    cw = w * 0.5
    bl = index(w, (x-cw,y-cw), depth, level)
    tl = index(w, (x-cw,y+cw), depth, level)
    tr = index(w, (x+cw,y+cw), depth, level)
    br = index(w, (x+cw,y-cw), depth, level)
    n.children = (bl, tl, tr, br)
    if level == depth:
        n.leaves = {}
    return n





