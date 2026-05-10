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



---

## Top Q&A — DSA (10 subtopics × 10 questions)

> All solutions in JS/TS, interview-grade. Each problem includes brief approach, complexity, and runnable code.

---

### A. Arrays

#### A1. Two Sum
Find indices `i,j` such that `arr[i]+arr[j]===target`.
**Approach:** hashmap of value→index. **O(n)** / **O(n)**.
```ts
function twoSum(a: number[], t: number): [number, number] | null {
  const m = new Map<number, number>();
  for (let i = 0; i < a.length; i++) {
    const need = t - a[i];
    if (m.has(need)) return [m.get(need)!, i];
    m.set(a[i], i);
  }
  return null;
}
```

#### A2. Best Time to Buy & Sell Stock
Single transaction max profit.
**Approach:** track min so far. **O(n)**.
```ts
function maxProfit(p: number[]): number {
  let min = Infinity, best = 0;
  for (const x of p) { min = Math.min(min, x); best = Math.max(best, x - min); }
  return best;
}
```

#### A3. Maximum Subarray (Kadane).
**O(n)**.
```ts
function maxSubArray(a: number[]): number {
  let cur = a[0], best = a[0];
  for (let i = 1; i < a.length; i++) { cur = Math.max(a[i], cur + a[i]); best = Math.max(best, cur); }
  return best;
}
```

#### A4. Product of Array Except Self.
No division. **O(n)** / **O(1)** extra.
```ts
function productExceptSelf(a: number[]): number[] {
  const n = a.length, out = new Array(n).fill(1);
  for (let i=1, l=a[0]; i<n; i++, l*=a[i-1]) out[i] = l;
  for (let i=n-2, r=a[n-1]; i>=0; i--, r*=a[i+1]) out[i] *= r;
  return out;
}
```

#### A5. Rotate Array by k.
Reverse trick.
```ts
function rotate(a: number[], k: number) {
  k %= a.length;
  const rev = (l: number, r: number) => { while(l<r){[a[l],a[r]]=[a[r],a[l]];l++;r--;} };
  rev(0, a.length-1); rev(0, k-1); rev(k, a.length-1);
}
```

#### A6. Move Zeroes (in place).
```ts
function moveZeroes(a: number[]) {
  let w = 0;
  for (let r=0; r<a.length; r++) if (a[r] !== 0) [a[w], a[r]] = [a[r], a[w++]];
}
```

#### A7. Container With Most Water.
Two pointers, move smaller side. **O(n)**.
```ts
function maxArea(h: number[]): number {
  let l=0, r=h.length-1, best=0;
  while (l<r) {
    best = Math.max(best, (r-l) * Math.min(h[l], h[r]));
    h[l] < h[r] ? l++ : r--;
  }
  return best;
}
```

#### A8. Merge Intervals.
Sort by start, merge.
```ts
function merge(iv: number[][]): number[][] {
  iv.sort((a,b)=>a[0]-b[0]);
  const out: number[][] = [];
  for (const i of iv) {
    if (out.length && i[0] <= out[out.length-1][1]) out[out.length-1][1] = Math.max(out[out.length-1][1], i[1]);
    else out.push(i);
  }
  return out;
}
```

#### A9. Find Duplicate (Floyd cycle).
Array of n+1 with values [1..n]. **O(n)** / **O(1)**.
```ts
function findDuplicate(a: number[]): number {
  let slow = a[0], fast = a[0];
  do { slow = a[slow]; fast = a[a[fast]]; } while (slow !== fast);
  slow = a[0];
  while (slow !== fast) { slow = a[slow]; fast = a[fast]; }
  return slow;
}
```

#### A10. Trapping Rain Water.
Two pointers.
```ts
function trap(h: number[]): number {
  let l=0, r=h.length-1, lm=0, rm=0, ans=0;
  while (l<r) {
    if (h[l] < h[r]) { lm = Math.max(lm, h[l]); ans += lm - h[l++]; }
    else            { rm = Math.max(rm, h[r]); ans += rm - h[r--]; }
  }
  return ans;
}
```

---

### B. Strings

#### B1. Valid Anagram.
Count chars.
```ts
function isAnagram(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  const c = new Array(26).fill(0);
  for (let i=0;i<a.length;i++){c[a.charCodeAt(i)-97]++; c[b.charCodeAt(i)-97]--;}
  return c.every(x => x===0);
}
```

#### B2. Valid Palindrome (alphanumeric).
```ts
function isPalindrome(s: string): boolean {
  s = s.toLowerCase().replace(/[^a-z0-9]/g, '');
  let l=0, r=s.length-1;
  while (l<r) if (s[l++] !== s[r--]) return false;
  return true;
}
```

#### B3. Longest Substring Without Repeating Characters.
Sliding window.
```ts
function lengthOfLongestSubstring(s: string): number {
  const m = new Map<string, number>();
  let best = 0, l = 0;
  for (let r=0; r<s.length; r++) {
    if (m.has(s[r]) && m.get(s[r])! >= l) l = m.get(s[r])! + 1;
    m.set(s[r], r);
    best = Math.max(best, r - l + 1);
  }
  return best;
}
```

#### B4. Group Anagrams.
Hashmap by sorted key.
```ts
function groupAnagrams(strs: string[]): string[][] {
  const m = new Map<string, string[]>();
  for (const s of strs) {
    const k = [...s].sort().join('');
    m.set(k, [...(m.get(k) ?? []), s]);
  }
  return [...m.values()];
}
```

#### B5. Longest Palindromic Substring.
Expand around center, **O(n²)**.
```ts
function longestPalindrome(s: string): string {
  let start=0, len=0;
  const exp = (l: number, r: number) => { while(l>=0 && r<s.length && s[l]===s[r]){l--;r++;} return [l+1, r-l-1]; };
  for (let i=0; i<s.length; i++) {
    for (const [l, ln] of [exp(i,i), exp(i,i+1)])
      if (ln > len) { start = l; len = ln; }
  }
  return s.substr(start, len);
}
```

#### B6. String to Integer (atoi).
```ts
function myAtoi(s: string): number {
  let i = 0, sign = 1, num = 0;
  while (s[i] === ' ') i++;
  if (s[i] === '+' || s[i] === '-') sign = s[i++] === '-' ? -1 : 1;
  while (i < s.length && s[i] >= '0' && s[i] <= '9') { num = num*10 + (+s[i++]); }
  return Math.max(-2**31, Math.min(2**31-1, sign*num));
}
```

#### B7. Implement strStr (substring search).
```ts
function strStr(h: string, n: string): number {
  if (!n) return 0;
  for (let i=0; i<=h.length-n.length; i++) if (h.substr(i, n.length) === n) return i;
  return -1;
}
```

#### B8. Encode/Decode Strings (Leetcode 271).
```ts
const encode = (xs: string[]) => xs.map(s => `${s.length}#${s}`).join('');
const decode = (s: string): string[] => {
  const out: string[] = []; let i=0;
  while (i<s.length) {
    const j = s.indexOf('#', i); const len = +s.slice(i, j);
    out.push(s.slice(j+1, j+1+len)); i = j+1+len;
  }
  return out;
};
```

#### B9. Minimum Window Substring.
Sliding window with counts (advanced).
```ts
function minWindow(s: string, t: string): string {
  const need = new Map<string, number>();
  for (const c of t) need.set(c, (need.get(c) ?? 0) + 1);
  let have = 0, want = need.size, l = 0, best: [number, number] = [-1, -1], bestLen = Infinity;
  const win = new Map<string, number>();
  for (let r=0; r<s.length; r++) {
    const c = s[r]; win.set(c, (win.get(c) ?? 0) + 1);
    if (need.has(c) && win.get(c) === need.get(c)) have++;
    while (have === want) {
      if (r - l + 1 < bestLen) { best = [l, r]; bestLen = r - l + 1; }
      const lc = s[l++]; win.set(lc, win.get(lc)! - 1);
      if (need.has(lc) && win.get(lc)! < need.get(lc)!) have--;
    }
  }
  return best[0] === -1 ? '' : s.slice(best[0], best[1]+1);
}
```

#### B10. Reverse Words in a String.
```ts
const reverseWords = (s: string) => s.trim().split(/\s+/).reverse().join(' ');
```

---

### C. Hashmap / Set

#### C1. Contains Duplicate.
```ts
const containsDuplicate = (a: number[]) => new Set(a).size !== a.length;
```

#### C2. First Non-Repeating Character.
```ts
function firstUniqChar(s: string): number {
  const c = new Map<string, number>();
  for (const ch of s) c.set(ch, (c.get(ch) ?? 0) + 1);
  for (let i=0; i<s.length; i++) if (c.get(s[i]) === 1) return i;
  return -1;
}
```

#### C3. Subarray Sum Equals K.
Prefix sum + hashmap.
```ts
function subarraySum(a: number[], k: number): number {
  const m = new Map<number, number>([[0,1]]);
  let sum=0, cnt=0;
  for (const x of a) { sum += x; cnt += m.get(sum-k) ?? 0; m.set(sum, (m.get(sum) ?? 0)+1); }
  return cnt;
}
```

#### C4. Top K Frequent Elements.
Bucket sort by frequency.
```ts
function topKFrequent(a: number[], k: number): number[] {
  const c = new Map<number, number>();
  for (const x of a) c.set(x, (c.get(x) ?? 0) + 1);
  const buckets: number[][] = Array.from({length: a.length+1}, () => []);
  for (const [n, f] of c) buckets[f].push(n);
  const out: number[] = [];
  for (let i=buckets.length-1; i>=0 && out.length<k; i--) out.push(...buckets[i]);
  return out.slice(0, k);
}
```

#### C5. Longest Consecutive Sequence.
**O(n)**.
```ts
function longestConsecutive(a: number[]): number {
  const s = new Set(a); let best = 0;
  for (const x of s) if (!s.has(x-1)) {
    let y = x; while (s.has(y+1)) y++;
    best = Math.max(best, y - x + 1);
  }
  return best;
}
```

#### C6. Valid Sudoku.
Three sets per row/col/box.
```ts
function isValidSudoku(b: string[][]): boolean {
  const seen = new Set<string>();
  for (let r=0; r<9; r++) for (let c=0; c<9; c++) {
    const v = b[r][c]; if (v === '.') continue;
    const keys = [`r${r}-${v}`, `c${c}-${v}`, `b${(r/3|0)}${(c/3|0)}-${v}`];
    for (const k of keys) { if (seen.has(k)) return false; seen.add(k); }
  }
  return true;
}
```

#### C7. Two Sum II (sorted, two pointers — alternative).
See A1; sorted version is two-pointer.

#### C8. Isomorphic Strings.
```ts
function isIsomorphic(s: string, t: string): boolean {
  const m1 = new Map(), m2 = new Map();
  for (let i=0; i<s.length; i++) {
    if ((m1.has(s[i]) && m1.get(s[i]) !== t[i]) || (m2.has(t[i]) && m2.get(t[i]) !== s[i])) return false;
    m1.set(s[i], t[i]); m2.set(t[i], s[i]);
  }
  return true;
}
```

#### C9. Word Pattern.
```ts
function wordPattern(p: string, s: string): boolean {
  const ws = s.split(' ');
  if (ws.length !== p.length) return false;
  const m1 = new Map(), m2 = new Map();
  for (let i=0; i<p.length; i++) {
    if ((m1.has(p[i]) && m1.get(p[i]) !== ws[i]) || (m2.has(ws[i]) && m2.get(ws[i]) !== p[i])) return false;
    m1.set(p[i], ws[i]); m2.set(ws[i], p[i]);
  }
  return true;
}
```

#### C10. Logger Rate Limiter.
```ts
class Logger {
  private m = new Map<string, number>();
  shouldPrintMessage(t: number, msg: string): boolean {
    if ((this.m.get(msg) ?? -Infinity) > t - 10) return false;
    this.m.set(msg, t); return true;
  }
}
```

---

### D. Two Pointers

#### D1. Reverse String.
```ts
function reverseString(a: string[]) {
  let l=0, r=a.length-1;
  while (l<r) [a[l++], a[r--]] = [a[r], a[l]];
}
```

#### D2. 3Sum.
```ts
function threeSum(a: number[]): number[][] {
  a.sort((x,y)=>x-y);
  const out: number[][] = [];
  for (let i=0; i<a.length-2; i++) {
    if (i>0 && a[i]===a[i-1]) continue;
    let l=i+1, r=a.length-1;
    while (l<r) {
      const s = a[i]+a[l]+a[r];
      if (s===0) { out.push([a[i],a[l],a[r]]); while(l<r&&a[l]===a[l+1])l++; while(l<r&&a[r]===a[r-1])r--; l++;r--;}
      else if (s<0) l++; else r--;
    }
  }
  return out;
}
```

#### D3. Remove Duplicates from Sorted Array.
```ts
function removeDuplicates(a: number[]): number {
  if (!a.length) return 0;
  let w = 1;
  for (let r=1; r<a.length; r++) if (a[r] !== a[r-1]) a[w++] = a[r];
  return w;
}
```

#### D4. Sort Colors (Dutch National Flag).
```ts
function sortColors(a: number[]) {
  let l=0, m=0, r=a.length-1;
  while (m<=r) {
    if (a[m]===0) [a[l],a[m]] = [a[m],a[l++]], m++;
    else if (a[m]===2) [a[m],a[r]] = [a[r],a[m--]], r--;
    else m++;
  }
}
```

#### D5. Partition List around pivot (linked list — see G).

#### D6. Squares of a Sorted Array.
```ts
function sortedSquares(a: number[]): number[] {
  const n = a.length, out = new Array(n);
  let l=0, r=n-1, w=n-1;
  while (l<=r) {
    if (Math.abs(a[l]) > Math.abs(a[r])) { out[w--] = a[l]*a[l]; l++; }
    else { out[w--] = a[r]*a[r]; r--; }
  }
  return out;
}
```

#### D7. Backspace String Compare.
```ts
function backspaceCompare(s: string, t: string): boolean {
  const build = (x: string) => { const st: string[] = []; for (const c of x) c === '#' ? st.pop() : st.push(c); return st.join(''); };
  return build(s) === build(t);
}
```

#### D8. Linked List Cycle (Floyd).
```ts
function hasCycle(head: any): boolean {
  let s = head, f = head;
  while (f && f.next) { s = s.next; f = f.next.next; if (s === f) return true; }
  return false;
}
```

#### D9. Middle of Linked List.
```ts
function middleNode(head: any): any {
  let s = head, f = head;
  while (f && f.next) { s = s.next; f = f.next.next; }
  return s;
}
```

#### D10. Trapping Rain Water (two-pointer) — see A10.

---

### E. Sliding Window

#### E1. Maximum Sum Subarray of Size K.
```ts
function maxSumK(a: number[], k: number): number {
  let s = 0; for (let i=0; i<k; i++) s += a[i];
  let best = s;
  for (let i=k; i<a.length; i++) { s += a[i] - a[i-k]; best = Math.max(best, s); }
  return best;
}
```

#### E2. Longest Substring with K Distinct Chars.
```ts
function longestKDistinct(s: string, k: number): number {
  const m = new Map<string, number>(); let l = 0, best = 0;
  for (let r=0; r<s.length; r++) {
    m.set(s[r], (m.get(s[r]) ?? 0) + 1);
    while (m.size > k) {
      m.set(s[l], m.get(s[l])! - 1);
      if (m.get(s[l]) === 0) m.delete(s[l]);
      l++;
    }
    best = Math.max(best, r - l + 1);
  }
  return best;
}
```

#### E3. Longest Substring Without Repeating — see B3.

#### E4. Permutation in String (Leetcode 567).
```ts
function checkInclusion(s1: string, s2: string): boolean {
  if (s1.length > s2.length) return false;
  const c1 = new Array(26).fill(0), c2 = new Array(26).fill(0);
  for (let i=0; i<s1.length; i++) { c1[s1.charCodeAt(i)-97]++; c2[s2.charCodeAt(i)-97]++; }
  const eq = () => c1.every((x,i)=>x===c2[i]);
  if (eq()) return true;
  for (let i=s1.length; i<s2.length; i++) {
    c2[s2.charCodeAt(i)-97]++; c2[s2.charCodeAt(i-s1.length)-97]--;
    if (eq()) return true;
  }
  return false;
}
```

#### E5. Find All Anagrams in a String.
Same as E4, push start indices.

#### E6. Minimum Size Subarray Sum.
```ts
function minSubArrayLen(target: number, a: number[]): number {
  let l=0, sum=0, best=Infinity;
  for (let r=0; r<a.length; r++) {
    sum += a[r];
    while (sum >= target) { best = Math.min(best, r-l+1); sum -= a[l++]; }
  }
  return best === Infinity ? 0 : best;
}
```

#### E7. Sliding Window Maximum.
Monotonic deque.
```ts
function maxSlidingWindow(a: number[], k: number): number[] {
  const dq: number[] = [], out: number[] = [];
  for (let i=0; i<a.length; i++) {
    while (dq.length && dq[0] <= i-k) dq.shift();
    while (dq.length && a[dq[dq.length-1]] < a[i]) dq.pop();
    dq.push(i);
    if (i >= k-1) out.push(a[dq[0]]);
  }
  return out;
}
```

#### E8. Longest Repeating Character Replacement.
```ts
function characterReplacement(s: string, k: number): number {
  const c = new Array(26).fill(0);
  let l=0, max=0, best=0;
  for (let r=0; r<s.length; r++) {
    c[s.charCodeAt(r)-65]++; max = Math.max(max, c[s.charCodeAt(r)-65]);
    if (r-l+1 - max > k) c[s.charCodeAt(l++)-65]--;
    best = Math.max(best, r-l+1);
  }
  return best;
}
```

#### E9. Fruit Into Baskets (Longest 2-distinct subarray).
Special case of E2 with k=2.

#### E10. Minimum Window Substring — see B9.

---

### F. Stack / Queue

#### F1. Valid Parentheses.
```ts
function isValid(s: string): boolean {
  const st: string[] = []; const m: Record<string,string> = {')':'(', ']':'[', '}':'{'};
  for (const c of s) {
    if ('([{'.includes(c)) st.push(c);
    else if (st.pop() !== m[c]) return false;
  }
  return st.length === 0;
}
```

#### F2. Min Stack.
Track min in parallel.
```ts
class MinStack {
  s: number[] = []; m: number[] = [];
  push(x: number){ this.s.push(x); this.m.push(this.m.length ? Math.min(this.m[this.m.length-1], x) : x); }
  pop(){ this.s.pop(); this.m.pop(); }
  top(){ return this.s[this.s.length-1]; }
  getMin(){ return this.m[this.m.length-1]; }
}
```

#### F3. Daily Temperatures (next greater).
Monotonic decreasing stack.
```ts
function dailyTemperatures(t: number[]): number[] {
  const out = new Array(t.length).fill(0); const st: number[] = [];
  for (let i=0; i<t.length; i++) {
    while (st.length && t[st[st.length-1]] < t[i]) { const j = st.pop()!; out[j] = i - j; }
    st.push(i);
  }
  return out;
}
```

#### F4. Evaluate RPN (Reverse Polish).
```ts
function evalRPN(tk: string[]): number {
  const st: number[] = [];
  for (const t of tk) {
    if ('+-*/'.includes(t)) {
      const b = st.pop()!, a = st.pop()!;
      st.push(t==='+'?a+b: t==='-'?a-b: t==='*'?a*b: (a/b)|0);
    } else st.push(+t);
  }
  return st[0];
}
```

#### F5. Implement Queue using Stacks.
```ts
class MyQueue { in: number[]=[]; out: number[]=[];
  push(x:number){this.in.push(x);}
  pop(){this.peek(); return this.out.pop()!;}
  peek(){if(!this.out.length) while(this.in.length) this.out.push(this.in.pop()!); return this.out[this.out.length-1];}
  empty(){return !this.in.length && !this.out.length;}
}
```

#### F6. Largest Rectangle in Histogram.
Monotonic stack.
```ts
function largestRectangleArea(h: number[]): number {
  const st: number[] = []; let best = 0;
  for (let i=0; i<=h.length; i++) {
    const cur = i === h.length ? 0 : h[i];
    while (st.length && h[st[st.length-1]] > cur) {
      const j = st.pop()!;
      const w = st.length ? i - st[st.length-1] - 1 : i;
      best = Math.max(best, h[j] * w);
    }
    st.push(i);
  }
  return best;
}
```

#### F7. Asteroid Collision.
```ts
function asteroidCollision(a: number[]): number[] {
  const st: number[] = [];
  for (const x of a) {
    let alive = true;
    while (alive && x < 0 && st.length && st[st.length-1] > 0) {
      if (st[st.length-1] < -x) st.pop();
      else if (st[st.length-1] === -x) { st.pop(); alive = false; }
      else alive = false;
    }
    if (alive) st.push(x);
  }
  return st;
}
```

#### F8. Decode String (3[a2[c]] → accaccacc).
```ts
function decodeString(s: string): string {
  const numSt: number[] = [], strSt: string[] = []; let cur = '', k = 0;
  for (const c of s) {
    if (c >= '0' && c <= '9') k = k*10 + +c;
    else if (c === '[') { numSt.push(k); strSt.push(cur); k=0; cur=''; }
    else if (c === ']') { cur = strSt.pop()! + cur.repeat(numSt.pop()!); }
    else cur += c;
  }
  return cur;
}
```

#### F9. LRU Cache (Map maintains insertion order).
```ts
class LRUCache {
  m = new Map<number, number>();
  constructor(private cap: number) {}
  get(k: number): number { if (!this.m.has(k)) return -1; const v = this.m.get(k)!; this.m.delete(k); this.m.set(k, v); return v; }
  put(k: number, v: number) {
    if (this.m.has(k)) this.m.delete(k);
    this.m.set(k, v);
    if (this.m.size > this.cap) this.m.delete(this.m.keys().next().value);
  }
}
```

#### F10. Implement Stack using Queues.
```ts
class MyStack { q: number[] = [];
  push(x:number){ this.q.push(x); for (let i=0; i<this.q.length-1; i++) this.q.push(this.q.shift()!); }
  pop(){return this.q.shift()!;} top(){return this.q[0];} empty(){return !this.q.length;}
}
```

---

### G. Linked List

#### G1. Reverse Linked List.
```ts
function reverseList(head: any): any {
  let prev = null, cur = head;
  while (cur) { const nxt = cur.next; cur.next = prev; prev = cur; cur = nxt; }
  return prev;
}
```

#### G2. Merge Two Sorted Lists.
```ts
function mergeTwoLists(a: any, b: any): any {
  const dummy: any = { next: null }; let t = dummy;
  while (a && b) { if (a.val <= b.val) { t.next = a; a = a.next; } else { t.next = b; b = b.next; } t = t.next; }
  t.next = a ?? b;
  return dummy.next;
}
```

#### G3. Linked List Cycle II (entry of cycle).
```ts
function detectCycle(head: any): any {
  let s = head, f = head;
  while (f && f.next) { s = s.next; f = f.next.next; if (s === f) {
    let p = head; while (p !== s) { p = p.next; s = s.next; } return p;
  }}
  return null;
}
```

#### G4. Remove Nth Node From End.
```ts
function removeNthFromEnd(head: any, n: number): any {
  const dummy: any = { next: head }; let f = dummy, s = dummy;
  for (let i=0; i<=n; i++) f = f.next;
  while (f) { f = f.next; s = s.next; }
  s.next = s.next.next;
  return dummy.next;
}
```

#### G5. Add Two Numbers (each node = digit, reversed).
```ts
function addTwoNumbers(a: any, b: any): any {
  const dummy: any = {next: null}; let t = dummy, carry = 0;
  while (a || b || carry) {
    const v = (a?.val ?? 0) + (b?.val ?? 0) + carry;
    carry = (v/10)|0; t.next = { val: v % 10, next: null }; t = t.next;
    a = a?.next; b = b?.next;
  }
  return dummy.next;
}
```

#### G6. Reorder List (L0→Ln→L1→Ln-1…).
Find mid, reverse second half, merge.

#### G7. Copy List with Random Pointer.
Interleave clone nodes; assign randoms; split.

#### G8. Palindrome Linked List.
Find mid, reverse, compare halves.

#### G9. Intersection of Two Linked Lists.
```ts
function getIntersectionNode(a: any, b: any): any {
  let p = a, q = b;
  while (p !== q) { p = p ? p.next : b; q = q ? q.next : a; }
  return p;
}
```

#### G10. Merge K Sorted Lists.
Min-heap (priority queue) of heads, **O(n log k)**.

---

### H. Trees

#### H1. Max Depth of Binary Tree.
```ts
function maxDepth(r: any): number { return r ? 1 + Math.max(maxDepth(r.left), maxDepth(r.right)) : 0; }
```

#### H2. Same Tree.
```ts
function isSameTree(p: any, q: any): boolean {
  if (!p && !q) return true; if (!p || !q || p.val !== q.val) return false;
  return isSameTree(p.left, q.left) && isSameTree(p.right, q.right);
}
```

#### H3. Invert Binary Tree.
```ts
function invertTree(r: any): any {
  if (!r) return null; [r.left, r.right] = [invertTree(r.right), invertTree(r.left)]; return r;
}
```

#### H4. Level Order Traversal (BFS).
```ts
function levelOrder(r: any): number[][] {
  if (!r) return []; const q = [r], out: number[][] = [];
  while (q.length) {
    const lvl: number[] = []; const n = q.length;
    for (let i=0; i<n; i++) { const x = q.shift(); lvl.push(x.val); if (x.left) q.push(x.left); if (x.right) q.push(x.right); }
    out.push(lvl);
  }
  return out;
}
```

#### H5. Validate BST.
```ts
function isValidBST(r: any, lo = -Infinity, hi = Infinity): boolean {
  if (!r) return true;
  return r.val > lo && r.val < hi && isValidBST(r.left, lo, r.val) && isValidBST(r.right, r.val, hi);
}
```

#### H6. Lowest Common Ancestor (BST).
```ts
function lowestCommonAncestor(r: any, p: any, q: any): any {
  if (p.val < r.val && q.val < r.val) return lowestCommonAncestor(r.left, p, q);
  if (p.val > r.val && q.val > r.val) return lowestCommonAncestor(r.right, p, q);
  return r;
}
```

#### H7. Diameter of Binary Tree.
```ts
function diameterOfBinaryTree(r: any): number {
  let best = 0;
  const dfs = (n: any): number => { if (!n) return 0; const l = dfs(n.left), R = dfs(n.right); best = Math.max(best, l+R); return 1+Math.max(l,R); };
  dfs(r); return best;
}
```

#### H8. Symmetric Tree.
```ts
function isSymmetric(r: any): boolean {
  const eq = (a: any, b: any): boolean => !a && !b ? true : (!a||!b||a.val!==b.val) ? false : eq(a.left, b.right) && eq(a.right, b.left);
  return eq(r?.left, r?.right);
}
```

#### H9. Serialize and Deserialize Binary Tree.
BFS-based; null nodes as `#`.

#### H10. Binary Tree Maximum Path Sum.
```ts
function maxPathSum(r: any): number {
  let best = -Infinity;
  const dfs = (n: any): number => { if (!n) return 0; const l = Math.max(0, dfs(n.left)), R = Math.max(0, dfs(n.right));
    best = Math.max(best, n.val + l + R); return n.val + Math.max(l, R); };
  dfs(r); return best;
}
```

---

### I. Graphs

#### I1. Number of Islands (DFS).
```ts
function numIslands(g: string[][]): number {
  let cnt = 0;
  const dfs = (r: number, c: number) => {
    if (r<0||c<0||r>=g.length||c>=g[0].length||g[r][c]!=='1') return;
    g[r][c] = '0'; dfs(r+1,c); dfs(r-1,c); dfs(r,c+1); dfs(r,c-1);
  };
  for (let r=0; r<g.length; r++) for (let c=0; c<g[0].length; c++) if (g[r][c]==='1') { dfs(r,c); cnt++; }
  return cnt;
}
```

#### I2. Clone Graph.
DFS with map of original → clone.

#### I3. Course Schedule (cycle detection / topo sort).
```ts
function canFinish(n: number, pre: number[][]): boolean {
  const g: number[][] = Array.from({length: n}, () => []), ind = new Array(n).fill(0);
  for (const [a,b] of pre) { g[b].push(a); ind[a]++; }
  const q: number[] = []; for (let i=0; i<n; i++) if (!ind[i]) q.push(i);
  let done = 0;
  while (q.length) { const x = q.shift()!; done++; for (const y of g[x]) if (--ind[y] === 0) q.push(y); }
  return done === n;
}
```

#### I4. Pacific Atlantic Water Flow.
Multi-source DFS from each ocean.

#### I5. Word Ladder (BFS).
Build neighbors via wildcard pattern map.

#### I6. Rotting Oranges (BFS multi-source).
```ts
function orangesRotting(g: number[][]): number {
  const q: [number,number,number][] = []; let fresh = 0;
  for (let r=0; r<g.length; r++) for (let c=0; c<g[0].length; c++) {
    if (g[r][c]===2) q.push([r,c,0]);
    if (g[r][c]===1) fresh++;
  }
  let t = 0;
  while (q.length) {
    const [r,c,m] = q.shift()!; t = Math.max(t, m);
    for (const [dr,dc] of [[1,0],[-1,0],[0,1],[0,-1]]) {
      const nr=r+dr, nc=c+dc;
      if (nr<0||nc<0||nr>=g.length||nc>=g[0].length||g[nr][nc]!==1) continue;
      g[nr][nc] = 2; fresh--; q.push([nr,nc,m+1]);
    }
  }
  return fresh ? -1 : t;
}
```

#### I7. Surrounded Regions.
DFS from borders, mark safe; flip rest.

#### I8. Network Delay Time (Dijkstra).
Priority queue from k.

#### I9. Number of Connected Components (Union-Find).
```ts
class UF { p: number[]; constructor(n: number){ this.p = Array.from({length:n}, (_,i)=>i); }
  find(x:number): number { return this.p[x]===x ? x : (this.p[x]=this.find(this.p[x])); }
  union(a:number,b:number){ this.p[this.find(a)] = this.find(b); }
}
```

#### I10. Cheapest Flights Within K Stops (Bellman-Ford variant).
Iterate K+1 times relaxing edges.

---

### J. Dynamic Programming

#### J1. Climbing Stairs.
```ts
function climbStairs(n: number): number {
  let a=1, b=1; for (let i=2; i<=n; i++) [a,b] = [b, a+b]; return b;
}
```

#### J2. House Robber.
```ts
function rob(a: number[]): number {
  let prev=0, cur=0;
  for (const x of a) [prev, cur] = [cur, Math.max(cur, prev+x)];
  return cur;
}
```

#### J3. Coin Change (min coins for amount).
```ts
function coinChange(c: number[], a: number): number {
  const dp = new Array(a+1).fill(Infinity); dp[0] = 0;
  for (let i=1; i<=a; i++) for (const x of c) if (i>=x) dp[i] = Math.min(dp[i], dp[i-x]+1);
  return dp[a] === Infinity ? -1 : dp[a];
}
```

#### J4. Longest Increasing Subsequence (LIS).
**O(n log n)** patience sorting.
```ts
function lengthOfLIS(a: number[]): number {
  const tails: number[] = [];
  for (const x of a) {
    let l=0, r=tails.length;
    while (l<r) { const m=(l+r)>>1; tails[m] < x ? l = m+1 : r = m; }
    tails[l] = x;
  }
  return tails.length;
}
```

#### J5. 0/1 Knapsack.
```ts
function knapsack(w: number[], v: number[], W: number): number {
  const dp = new Array(W+1).fill(0);
  for (let i=0; i<w.length; i++) for (let j=W; j>=w[i]; j--) dp[j] = Math.max(dp[j], dp[j-w[i]] + v[i]);
  return dp[W];
}
```

#### J6. Edit Distance.
```ts
function minDistance(a: string, b: string): number {
  const m = a.length, n = b.length;
  const dp = Array.from({length: m+1}, (_,i) => Array.from({length: n+1}, (_,j) => i===0 ? j : j===0 ? i : 0));
  for (let i=1; i<=m; i++) for (let j=1; j<=n; j++)
    dp[i][j] = a[i-1]===b[j-1] ? dp[i-1][j-1] : 1 + Math.min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]);
  return dp[m][n];
}
```

#### J7. Word Break.
```ts
function wordBreak(s: string, dict: string[]): boolean {
  const set = new Set(dict); const dp = new Array(s.length+1).fill(false); dp[0] = true;
  for (let i=1; i<=s.length; i++) for (let j=0; j<i; j++) if (dp[j] && set.has(s.slice(j,i))) { dp[i] = true; break; }
  return dp[s.length];
}
```

#### J8. Unique Paths (m×n grid).
```ts
function uniquePaths(m: number, n: number): number {
  const dp = new Array(n).fill(1);
  for (let i=1; i<m; i++) for (let j=1; j<n; j++) dp[j] += dp[j-1];
  return dp[n-1];
}
```

#### J9. Longest Common Subsequence.
```ts
function longestCommonSubsequence(a: string, b: string): number {
  const m = a.length, n = b.length;
  const dp = Array.from({length: m+1}, () => new Array(n+1).fill(0));
  for (let i=1; i<=m; i++) for (let j=1; j<=n; j++)
    dp[i][j] = a[i-1]===b[j-1] ? dp[i-1][j-1]+1 : Math.max(dp[i-1][j], dp[i][j-1]);
  return dp[m][n];
}
```

#### J10. Maximum Product Subarray.
```ts
function maxProduct(a: number[]): number {
  let lo = a[0], hi = a[0], best = a[0];
  for (let i=1; i<a.length; i++) {
    const cands = [a[i], a[i]*lo, a[i]*hi];
    lo = Math.min(...cands); hi = Math.max(...cands); best = Math.max(best, hi);
  }
  return best;
}
```
