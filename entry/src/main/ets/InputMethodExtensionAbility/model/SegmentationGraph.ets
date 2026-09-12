class SplitEdge<T> {
    syllable: T;
    end: number;
    constructor(syllable: T, end: number) {
        this.syllable = syllable;
        this.end = end;
    }
}

class SplitNode<T> {
    edge: SplitEdge<T>;
    previous: number;
    constructor(edge: SplitEdge<T>, previous: number) {
        this.edge = edge;
        this.previous = previous;
    }
}

/** Build each syllable edge once; enumerate schemes by length, then syllable count. */
export class SegmentationGraph {
    static split<T>(codes: number[], radix: number, lookup: Map<number, T>): T[][] {
        if (codes.length === 0) return [];
        const edges: SplitEdge<T>[][] = [];
        for (let start = 0; start < codes.length; start++) {
            const options: SplitEdge<T>[] = [];
            let code = 0;
            for (let end = start; end < Math.min(codes.length, start + 6); end++) {
                code = code * radix + codes[end];
                const syllable = lookup.get(code);
                if (syllable !== undefined) options.push(new SplitEdge(syllable, end + 1));
            }
            edges.push(options);
        }
        const nodes: SplitNode<T>[] = edges[0].map((edge) => new SplitNode(edge, -1));
        for (let index = 0; index < nodes.length; index++) {
            const node = nodes[index];
            if (node.edge.end === codes.length) continue;
            for (const edge of edges[node.edge.end]) nodes.push(new SplitNode(edge, index));
        }
        const indices = nodes.map((_, index) => index).sort((a, b) => nodes[b].edge.end - nodes[a].edge.end || a - b);
        return indices.map((index) => {
            const scheme: T[] = [];
            while (index >= 0) {
                scheme.push(nodes[index].edge.syllable);
                index = nodes[index].previous;
            }
            return scheme.reverse();
        });
    }
}
