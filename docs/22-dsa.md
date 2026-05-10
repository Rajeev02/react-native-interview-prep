## 22. DSA must-knows

### Patterns (cover 80% of mediums)
| Pattern | Examples |
|---|---|
| Two pointers | Reverse, palindrome, 3-sum |
| Sliding window | Longest substring, max sum subarray |
| Hashmap freq | Anagrams, two-sum, group anagrams |
| Prefix sum | Subarray sum equals K |
| Binary search | Search rotated, sqrt, kth element |
| BFS / DFS | Trees, islands, course schedule |
| Heap (top-K) | Kth largest, merge K sorted |
| Monotonic stack | Next greater, daily temps |
| DP (1D, easy) | House robber, coin change, climb stairs |
| Linked list | Reverse, cycle, merge two |
| Trie | Word search, autocomplete |
| LRU cache | (Razorpay/PhonePe favorite) |

### LRU cache (memorize)
```js
class LRU {
  constructor(cap) { this.cap = cap; this.map = new Map(); }
  get(k) {
    if (!this.map.has(k)) return -1;
    const v = this.map.get(k); this.map.delete(k); this.map.set(k, v);
    return v;
  }
  put(k, v) {
    if (this.map.has(k)) this.map.delete(k);
    this.map.set(k, v);
    if (this.map.size > this.cap) this.map.delete(this.map.keys().next().value);
  }
}
```

### Plan
- 3 LeetCode mediums/day for 4 weeks.
- Cover all patterns above at least 2× each.
- 1 hard/week (just for exposure).

---

