"""
reranker_bridge.py — Everest DELTA
Wires mem0 reranker pattern into MemPalace L3 deep search.
"""
from typing import List, Dict
try:
    from .reranker import SentenceTransformerReranker
    from .entity import extract_entities
    _DELTA_AVAILABLE = True
except Exception:
    _DELTA_AVAILABLE = False


def rerank_drawer_hits(query: str, hits: List[Dict], top_k: int = 5) -> List[Dict]:
    if not _DELTA_AVAILABLE or not hits:
        return hits[:top_k]
    try:
        reranker = SentenceTransformerReranker()
        docs = [h.get("content", "") for h in hits]
        scored = reranker.rerank(query, docs)
        order = [idx for idx, _ in sorted(enumerate(scored), key=lambda x: -x[1])]
        return [hits[i] for i in order[:top_k]]
    except Exception:
        return hits[:top_k]


def entity_boost(query: str, hits: List[Dict]) -> List[Dict]:
    if not _DELTA_AVAILABLE:
        return hits
    try:
        q_entities = set(extract_entities(query) or [])
        if not q_entities:
            return hits
        for h in hits:
            h_ents = set(extract_entities(h.get("content", "")) or [])
            h["_entity_overlap"] = len(q_entities & h_ents)
        return sorted(hits, key=lambda x: -x.get("_entity_overlap", 0))
    except Exception:
        return hits
