// #define protected public
#include <bits/stdc++.h>
using namespace std;
// using namespace __gnu_pbds; template<typename T> using ordered_set = tree<T, null_type, less<T>, rb_tree_tag, tree_order_statistics_node_update>; template<typename T1, typename T2> using hash_map = gp_hash_table<T1, T2>; template<typename T, typename Cmp = less<T>> using gp_priority_queue = __gnu_pbds::priority_queue<T, Cmp, pairing_heap_tag>;
/*is_string*/ template<typename T, typename = void> struct is_string : false_type {}; template<typename T> struct is_string<T, enable_if_t<is_same_v<decay_t<T>, string> || is_same_v<decay_t<T>, char*> || is_same_v<decay_t<T>, const char*>>> : true_type {}; /*is_iterable*/ template<typename T, typename = void> struct is_iterable : false_type {}; template<typename T> struct is_iterable<T, enable_if_t<!is_string<T>::value && is_same_v<decltype(begin(declval<T>())), decltype(end(declval<T>()))>>> : true_type {}; /*is_map*/ template<typename T, typename = void> struct is_map : false_type {}; template<typename T> struct is_map<T, void_t<typename T::key_type, typename T::mapped_type>> : true_type {}; /*is_set*/ template<typename T, typename = void> struct is_set : false_type {}; template<typename T> struct is_set<T, enable_if_t<!is_map<T>::value && is_same_v<typename T::key_type, typename T::value_type>>> : true_type {};
template<typename T1, typename T2> ostream& operator<<(ostream& out, const pair<T1, T2>& cont); template<typename... Ts> ostream& operator<<(ostream& out, const tuple<Ts...>& t); template<typename C, typename, typename> ostream& operator<<(ostream& os, const C& c);
/*pair*/ template<typename T1, typename T2> ostream& operator<<(ostream& out, const pair<T1, T2>& cont) { return out << "(" << cont.first << ", " << cont.second << ")"; } /*tuple*/ template<typename... Ts> ostream& operator<<(ostream& out, const tuple<Ts...>& t) { out << "("; int i = 0; apply([&](const auto&... args) { ((out << (i++ ? ", " : "") << args), ...); }, t); return out << ")"; } /*stl*/ template<typename C, typename = decltype(begin(declval<C>())), typename = enable_if_t<!is_string<C>::value>> ostream& operator<<(ostream& os, const C& c) { os << (is_map<C>::value || is_set<C>::value ? '{' : '['); for (auto it = begin(c); it != end(c); ++it) { if (it != begin(c)) os << ", "; if constexpr (is_map<C>::value) os << it->first << ":" << it->second; else os << *it; } return os << (is_map<C>::value || is_set<C>::value ? '}' : ']'); }
/*get*/ template<typename T> T get() { T x; cin >> x; return x; } /*create n-d vector*/ template<typename T, typename... Args> auto avec(T elem, size_t sz, Args... dim) { if constexpr (sizeof...(dim) == 0) return vector<T>(sz, elem); else return vector(sz, avec(elem, dim...)); } /*print n-d vector*/ template<typename C> string svec(const C& c) { stringstream ss; if constexpr (is_iterable<C>::value) { if (is_iterable<decltype(*begin(c))>::value) { for (auto it = begin(c); it != end(c); ++it) ss << (it == begin(c) ? "" : "\n") << svec(*it); } else { for (auto it = begin(c); it != end(c); ++it) ss << (it == begin(c) ? "" : " ") << *it; } } else ss << c; return ss.str(); }
#ifdef LOCAL
#include <dbg.h>
#else
#pragma GCC diagnostic ignored "-Wunused-value"
#define dbg(...) (__VA_ARGS__)
#endif
#define rep(i, lo, hi) for (ll i = (ll)(lo); i < (ll)(hi); ++i)
#define rof(i, hi, lo) for (ll i = (ll)(hi); i >= (ll)(lo); --i)
#define all(x) begin(x), end(x)
#define sz(x) ((ll)((x).size()))
#define vec vector
#define fst first
#define snd second

using ll = long long; using ld = long double; using point = complex<ll> /*HERE*/; using iii = int; using yeee = iii; using lll = long long; using ull = unsigned long long; using pll = pair<ll, ll>; using vb = vector<char>; using vvb = vector<vb>; using vll = vector<ll>; using vvll = vector<vll>; using vpll = vector<pll>; template<size_t N> using arll = array<ll, N>;
constexpr ll MOD = true ? 1e9 + 7 : 998244353 /*HERE*/; constexpr long long INFll = (long long)(1.001e18) - 1; constexpr int INFi = (int)(1.01e9) - 1; constexpr ll INF = sizeof(ll) == sizeof(int) ? ll(INFi) : ll(INFll); char newl = '\n'; ld get_time() { return ld(chrono::duration_cast<chrono::nanoseconds>( chrono::high_resolution_clock::now().time_since_epoch()).count()) / 1e9; } ld START_TIME = get_time(); mt19937_64 rand_mt64((int)(START_TIME * 1e9)); mt19937 rand_mt((int)(START_TIME * 1e9));
ll sign(ld x) { return (x > 0) - (x < 0); } template<typename T> T setmin(T &x, T y) { return x = min(x, y); } template<typename T> T setmax(T &x, T y) { return x = max(x, y); } ll fmod(ll x, ll mod) { if (!mod) return x; if (abs(x) >= mod) x %= mod; if (x < 0) x += mod; return x; } template<bool domod=true> ll fpow(ll b, ll exp, ll mod=0) { ll res = 1; if constexpr (domod) { for (; exp; exp /= 2, b = b * b % mod) if (exp & 1) res = res * b % mod; } else { for (; exp; exp /= 2, b = b * b) if (exp & 1) res = res * b; } return res; } ll mMOD(ll& x) { return x %= MOD; } template<bool maybe_negative=false> ll aMOD(ll& x, const ll a) { x = (x + a) % MOD; if constexpr (maybe_negative) if (x < 0) x += MOD; return x; }
void main_init(bool fast_cio = true, string input_file = "", string output_file = "") { srand(unsigned(time(0))); if (fast_cio) { cin.tie(0)->sync_with_stdio(false); cin.exceptions(cin.failbit); } if (input_file != "" && freopen(input_file.c_str(), "r", stdin)) {}; if (output_file != "" && freopen(output_file.c_str(), "w", stdout)) {}; }
using solve_rt = void /*HERE*/; solve_rt solve(); yeee main() { main_init(); for (ll TCn = true /*HERE*/ ? 1 : get<ll>(), TCi = 0; TCi < TCn; ++TCi) { solve(); } }

solve_rt solve() {

}
