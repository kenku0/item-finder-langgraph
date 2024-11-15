import os
from typing import List, Dict, Any, Annotated
from langgraph.graph import Graph
from langgraph.prebuilt import ToolExecutor
from langchain_anthropic import ChatAnthropic
from tavily import TavilyClient
from langchain.tools import tool
from pydantic import BaseModel, Field
from dotenv import load_dotenv
from operator import itemgetter
from typing import TypedDict
import praw
import json
import time

# Load environment variables
load_dotenv()

#conda activate itemfinder

#change reddit: limit, taviy: max_results

# Initialize clients
def initialize_reddit(item_name: str):
    return praw.Reddit(
        client_id=os.getenv("REDDIT_CLIENT_ID"),
        client_secret=os.getenv("REDDIT_CLIENT_SECRET"),
        user_agent="ItemFinder/1.0"
    )
tavily = TavilyClient(api_key=os.getenv("TAVILY_API_KEY"))
model = ChatAnthropic(
    model="claude-3-sonnet-20240229",
    anthropic_api_key=os.getenv("ANTHROPIC_API_KEY"),
    max_tokens=4096
)

class ItemRecommendation(BaseModel):
    name: str = Field(description="Name of the recommended item")
    year_made: str | int | None = Field(default=None, description="Year/month made if known")
    purchase_link: str | None = Field(default=None, description="Amazon or e-commerce link")
    price: str | float | None = Field(default=None, description="Approximate price")
    brand: str | None = Field(default=None, description="Brand name")
    description: str | None = Field(default="No description available", description="Detailed item description")
    ranking_reason: str | None = Field(default="No ranking reason provided", description="Explanation for this ranking")
    source_url: str | None = Field(default=None, description="URL where this recommendation was found")
    source_type: str | None = Field(default=None, description="Whether from Reddit or web search")

class GraphState(TypedDict):
    item_name: str
    reddit_data: List[Dict[str, Any]]
    web_data: List[Dict[str, Any]]
    recommendations: List[ItemRecommendation]

@tool
def search_reddit(query: str) -> List[Dict[str, Any]]:
    """Search Reddit for item recommendations"""
    reddit_client = initialize_reddit(query)
    results = []
    try:
        print("\n🔍 Searching Reddit...")
        for submission in reddit_client.subreddit("all").search(query, limit=5, sort="relevance"):
            # Get the submission with comments
            submission.comments.replace_more(limit=20)  # Load 'More Comments'
            top_comments = []
            
            # Get top comments
            for comment in submission.comments.list()[:15]:  # Get top 15 comments
                if hasattr(comment, 'body') and len(comment.body.strip()) > 10:
                    top_comments.append({
                        'text': comment.body,
                        'score': comment.score
                    })
            
            result = {
                "title": submission.title,
                "url": f"https://reddit.com{submission.permalink}",
                "text": submission.selftext,
                "comments": top_comments,
                "score": submission.score
            }
            results.append(result)
            
            # Generate a quick summary using Claude
            summary_prompt = f"""Briefly summarize this Reddit post in 1-2 sentences:
            Title: {submission.title}
            Content: {submission.selftext}"""
            
            try:
                summary_response = model.invoke(summary_prompt)
                summary = summary_response.content.strip()
            except Exception as e:
                summary = "Error generating summary"
            
            print(f"\n📝 Found Reddit post: {result['title']}")
            print(f"📌 Summary: {summary}")
            print(f"💬 Number of comments analyzed: {len(top_comments)}")
            print(f"🔗 Post URL: {result['url']}\n")
            
    except Exception as e:
        print(f"\n❌ Reddit search error: {e}")
    
    return results

@tool
def search_tavily(query: str) -> List[Dict[str, Any]]:
    """Search the internet using Tavily for item recommendations"""
    print(f"\n🌐 Searching web with Tavily for: {query}")
    try:
        search_result = tavily.search(
            query=query,
            search_depth="advanced",
            max_results=30,
            include_answer=True,
            include_raw_content=True
        )
        print(f"\n📊 Found {len(search_result['results'])} web results")
        for result in search_result['results'][:3]:  # Show first 3 results as preview
            print(f"\n📝 Found webpage: {result.get('title', 'No title')} - {result.get('url', 'No URL')}")
        return search_result['results']
    except Exception as e:
        print(f"\n❌ Tavily search error: {e}")
        return []

def analyze_reddit_data(reddit_results: List[Dict[str, Any]], item_name: str) -> List[Dict[str, Any]]:
    """Use Claude to analyze and synthesize Reddit recommendations"""
    print("\n🤖 Analyzing Reddit data with Claude...")
    
    # Check if we have valid Reddit data
    if not reddit_results or not isinstance(reddit_results, list):
        print("⚠️ No valid Reddit data to analyze")
        return []
        
    # Print raw data for debugging
    print("\nRaw Reddit data:")
    print(json.dumps(reddit_results, indent=2))
    
    prompt = f"""You are analyzing Reddit discussions about {item_name}.
    For each Reddit post and its comments, identify up to 3 most mentioned or highly regarded items.

    Reddit Data to Analyze: {reddit_results}

    For each Reddit post, provide:
    1. A brief summary of what the post was about
    2. Up to 3 products mentioned positively, with these details for each:
        - name (required): Specific product name
        - description: What the product does/is
        - ranking_reason: Include specific quotes or paraphrased user experiences
        - brand (if mentioned)
        - price (if mentioned)
        - source_url: The Reddit post URL

    Return your analysis as a JSON array where each item represents a product recommendation.
    Example format:
    [
        {{
            "name": "Product X Gel",
            "description": "Strong hold hair gel with natural ingredients",
            "ranking_reason": "Multiple users praised it: 'Best hold I've ever had' and 'Doesn't leave residue'",
            "brand": "Brand X",
            "price": "$25",
            "source_url": "reddit-url-here",
            "post_context": "From discussion about long-lasting hair products"
        }}
    ]

    First summarize each post, then extract the recommendations. If a post has no clear recommendations, you can skip it.
    Include direct quotes or specific user experiences in the ranking_reason when possible."""

    try:
        response = model.invoke(prompt)
        # Find the JSON array in the response
        start_idx = response.content.find('[')
        end_idx = response.content.rfind(']') + 1
        if start_idx == -1 or end_idx == 0:
            print("⚠️ No valid JSON array found in Claude's response")
            return []
            
        cleaned_json = response.content[start_idx:end_idx]
        results = json.loads(cleaned_json)
        
        print("\n📊 Claude's Reddit Analysis Results:")
        print("Post Summaries and Top Products:")
        print(json.dumps(results, indent=2))
        
        # Validate each recommendation has required fields
        validated_results = []
        for rec in results:
            if rec.get('name') and rec.get('description') and rec.get('ranking_reason'):
                validated_results.append(rec)
            else:
                print(f"⚠️ Skipping invalid recommendation: {rec}")
        
        return validated_results
    except Exception as e:
        print(f"❌ Reddit analysis error: {e}")
        print("Full response from Claude:", response.content if 'response' in locals() else "No response")
        return []

def analyze_web_data(web_results: List[Dict[str, Any]], item_name: str) -> List[Dict[str, Any]]:
    """Use Claude to analyze and synthesize web search recommendations"""
    print("\n🤖 Analyzing web data with Claude...")
    
    prompt = f"""Analyze these web search results about {item_name} and extract the top 5 most recommended items.
    Focus on products that are frequently mentioned positively or highly rated across multiple sources.

    Web Data: {web_results}

    Return ONLY a valid JSON array (no other text) of EXACTLY 5 recommendations.
    Each recommendation should include: name (required), brand (if mentioned), description, why it's recommended, 
    approximate price (if mentioned), and source URL.

    Example format:
    [
        {{
            "name": "Product Name",
            "brand": "Brand Name",
            "description": "Description text",
            "ranking_reason": "Why this is recommended",
            "price": "Price if known",
            "source_url": "URL"
        }}
    ]

    Focus on extracting specific product details and expert reviews."""

    try:
        response = model.invoke(prompt)
        cleaned_json = response.content[response.content.find('['):].strip()
        results = json.loads(cleaned_json)
        print("\n📊 Claude's Web Analysis Results:")
        print(json.dumps(results, indent=2))
        return results
    except Exception as e:
        print(f"❌ Web analysis error: {e}")
        return []

def create_research_graph():
    def reddit_research(state: GraphState) -> GraphState:
        print("\n🔄 Starting Reddit research...")
        try:
            results = search_reddit.invoke(state["item_name"])
            # Add Claude analysis of Reddit results
            analyzed_results = analyze_reddit_data(results, state["item_name"])
            state["reddit_data"] = analyzed_results
            return state
        except Exception as e:
            print(f"❌ Reddit research error: {e}")
            state["reddit_data"] = []
            return state

    def web_research(state: GraphState) -> GraphState:
        print("\n🔄 Starting web research...")
        try:
            query = f"best {state['item_name']} recommendations reviews quality design functionality"
            results = search_tavily.invoke(query)
            # Add Claude analysis of web results
            analyzed_results = analyze_web_data(results, state["item_name"])
            state["web_data"] = analyzed_results
            return state
        except Exception as e:
            print(f"❌ Web research error: {e}")
            state["web_data"] = []
            return state

    def analyze_and_rank(state: GraphState) -> GraphState:
        print("\n🔄 Starting final analysis...")
        
        try:
            # Debug prints
            print("\nReddit data:", json.dumps(state['reddit_data'], indent=2))
            print("\nWeb data:", json.dumps(state['web_data'], indent=2))
            
            # Combine available recommendations
            available_items = state['reddit_data'] + state['web_data']
            num_items = min(8, len(available_items))  # Only request as many items as we have
            
            final_prompt = f"""Given these pre-analyzed recommendations for {state['item_name']}, 
            provide the BEST {num_items} items overall, ranked by quality, value, and user satisfaction.
            DO NOT add any null or empty items to pad the results.

            Reddit Recommendations: {state['reddit_data']}
            Web Recommendations: {state['web_data']}

            Return ONLY a valid JSON array (no other text) of up to {num_items} recommendations.
            Each recommendation MUST include these fields with non-null values:
            - name (required string)
            - description (required string)
            - ranking_reason (required string)

            Optional fields that can be null:
            - brand
            - price
            - source_url
            - source_type
            - year_made

            Example format:
            [
                {{
                    "name": "Product Name",
                    "description": "Description text",
                    "ranking_reason": "Why this rank",
                    "brand": "Brand Name",
                    "price": "100",
                    "source_url": "URL",
                    "source_type": "Reddit",
                    "year_made": "2024"
                }}
            ]"""

            response = model.invoke(final_prompt)
            final_json = response.content[response.content.find('['):].strip()
            recommendations = json.loads(final_json)
            
            # Debug print
            print("\nFinal recommendations before conversion:", json.dumps(recommendations, indent=2))
            
            # Validate recommendations before conversion
            validated_recommendations = []
            for rec in recommendations:
                if rec.get('name') and rec.get('description') and rec.get('ranking_reason'):
                    validated_recommendations.append(rec)
                else:
                    print(f"\n⚠️ Skipping invalid recommendation: {rec}")
            
            state["recommendations"] = [ItemRecommendation(**item) for item in validated_recommendations]
            return state

        except Exception as e:
            print(f"❌ Final analysis error: {e}")
            print("Full error details:", str(e))
            state["recommendations"] = []
            return state

    def end_research(state: GraphState) -> GraphState:
        """Final node to ensure state is returned"""
        return state

    # Create the graph
    workflow = Graph()

    # Add nodes
    workflow.add_node("reddit_research", reddit_research)
    workflow.add_node("web_research", web_research)
    workflow.add_node("analyze", analyze_and_rank)
    workflow.add_node("end", end_research)  # Add final node

    # Define edges
    workflow.add_edge("reddit_research", "web_research")
    workflow.add_edge("web_research", "analyze")
    workflow.add_edge("analyze", "end")  # Connect to final node

    # Set entry point
    workflow.set_entry_point("reddit_research")
    workflow.set_finish_point("end")  # Add this line to specify the finish point
    return workflow.compile()

def format_output(recommendations: List[ItemRecommendation]) -> str:
    """Format the recommendations into a detailed output"""
    output = "Top 4 Recommended Items:\n\n"
    
    # Detailed top 4
    for i, item in enumerate(recommendations[:4], 1):
        output += f"{i}. {item.name}\n"
        output += f"   Year: {item.year_made}\n"
        output += f"   Brand: {item.brand}\n"
        output += f"   Price: {item.price}\n"
        output += f"   Description: {item.description}\n"
        output += f"   Why This Rank: {item.ranking_reason}\n"
        output += f"   Purchase Link: {item.purchase_link}\n"
        output += f"   Source: {item.source_type} - {item.source_url}\n\n"
    
    # Table for remaining items
    output += "\nRemaining Recommendations:\n"
    output += "Rank | Item | Brand | Description | Reason | Purchase Link | Source\n"
    output += "-" * 100 + "\n"
    
    for i, item in enumerate(recommendations[4:], 5):
        output += f"{i} | {item.name} | {item.brand} | {item.description[:30]}... | "
        output += f"{item.ranking_reason[:30]}... | {item.purchase_link} | "
        output += f"{item.source_type}: {item.source_url}\n"
    
    return output

def main():
    item_name = input("\n🔍 What item would you like to research? ")
    print("\n🔄 Starting search process...")
    
    if not item_name.strip():
        print("\n❌ Error: Please enter a valid item name")
        return
    
    # Initialize Reddit with user's input
    global reddit
    try:
        reddit = initialize_reddit(item_name)
        print("✅ Reddit initialized successfully")
    except Exception as e:
        print(f"❌ Reddit initialization error: {e}")
    
    print("\n📱 Initializing research workflow...")
    research_graph = create_research_graph()
    
    initial_state: GraphState = {
        "item_name": item_name,
        "reddit_data": [],
        "web_data": [],
        "recommendations": []
    }
    
    try:
        print("\n🔍 Executing research workflow...")
        final_state = research_graph.invoke(initial_state)
        
        # Check if final_state is None
        if final_state is None:
            print("\n⚠️ No results returned from workflow. Please try again.")
            return
            
        # Debug print to see what we got
        recommendations = final_state.get('recommendations', [])
        print(f"\n📊 Final state contains {len(recommendations)} recommendations")
        
        # Changed condition to properly check recommendations
        if recommendations:
            print("\n✨ Final formatted recommendations:")
            print(format_output(recommendations))
        else:
            print("\n⚠️ No recommendations found. Please try a different search term.")
    except Exception as e:
        print(f"\n❌ An error occurred: {e}")
        import traceback
        print(traceback.format_exc())

if __name__ == "__main__":
    main()