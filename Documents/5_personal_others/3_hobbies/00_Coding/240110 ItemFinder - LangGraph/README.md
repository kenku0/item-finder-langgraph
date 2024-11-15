# Item Finder - LangGraph

> 🔍 An intelligent item recommendation system built with LangGraph, Reddit API, and web search capabilities

## Overview

**Note: This is a November 2024 project**

Item Finder is a Python-based recommendation engine that leverages LangGraph's workflow orchestration to aggregate and analyze product recommendations from multiple sources. It combines Reddit discussions and web search results to provide comprehensive, ranked recommendations for any item you're researching.

## Features

- **Multi-source Research**: Aggregates data from Reddit discussions and web searches
- **Intelligent Analysis**: Uses Claude AI to analyze and synthesize recommendations
- **Ranked Results**: Provides top recommendations with detailed explanations
- **Rich Context**: Includes user experiences, expert reviews, and pricing information
- **LangGraph Workflow**: Demonstrates advanced workflow orchestration patterns

## Architecture

The system uses LangGraph to orchestrate a multi-step research workflow:

```
Reddit Research → Web Research → Analysis & Ranking → Formatted Output
```

### Key Components

1. **Reddit Research Node**: Searches Reddit for relevant discussions and extracts recommendations from posts and comments
2. **Web Research Node**: Uses Tavily API to search the web for expert reviews and recommendations
3. **Analysis Node**: Uses Claude AI to synthesize all data and produce ranked recommendations
4. **State Management**: Maintains workflow state throughout the research process

## Prerequisites

- Python 3.8+
- Reddit API credentials
- Anthropic API key (for Claude)
- Tavily API key (for web search)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/kenku0/item-finder-langgraph.git
cd item-finder-langgraph
```

2. Create a virtual environment:
```bash
python -m venv myenv
source myenv/bin/activate  # On Windows: myenv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your API keys
```

## Configuration

Create a `.env` file with the following variables:

```env
ANTHROPIC_API_KEY=your_anthropic_api_key
TAVILY_API_KEY=your_tavily_api_key
REDDIT_CLIENT_ID=your_reddit_client_id
REDDIT_CLIENT_SECRET=your_reddit_client_secret
```

## Usage

Run the application:

```bash
python main.py
```

When prompted, enter the item you want to research:

```
🔍 What item would you like to research? wireless earbuds
```

The system will then:
1. Search Reddit for relevant discussions
2. Perform web searches for expert reviews
3. Analyze all data using AI
4. Present ranked recommendations with detailed information

### Example Output

```
Top 4 Recommended Items:

1. Sony WF-1000XM4
   Year: 2021
   Brand: Sony
   Price: $279
   Description: Premium noise-canceling wireless earbuds with industry-leading ANC
   Why This Rank: Multiple Reddit users praise: "Best ANC I've experienced" and "Worth every penny"
   Purchase Link: https://www.amazon.com/...
   Source: Reddit - https://reddit.com/r/headphones/...

[Additional recommendations follow...]
```

## Technical Details

### Dependencies

- **langgraph**: Workflow orchestration framework
- **langchain_anthropic**: Claude AI integration
- **praw**: Reddit API wrapper
- **tavily**: Web search API client
- **pydantic**: Data validation and settings management
- **python-dotenv**: Environment variable management

### Workflow States

The system maintains the following state throughout execution:
- `item_name`: The item being researched
- `reddit_data`: Analyzed Reddit recommendations
- `web_data`: Analyzed web search results
- `recommendations`: Final ranked recommendations

### Error Handling

The system includes comprehensive error handling for:
- API failures
- Invalid responses
- Missing data
- Network issues

## Customization

You can adjust the research depth by modifying:
- Reddit search limit (line 61 in main.py)
- Web search results count (line 112 in main.py)
- Number of comments analyzed per Reddit post (line 67 in main.py)

## Limitations

- Reddit API rate limits apply
- Requires active API keys for all services
- Results quality depends on available online discussions
- Processing time varies based on item complexity

## Contributing

This is a demonstration project from November 2024. Feel free to fork and adapt for your own use cases.

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Built with [LangGraph](https://github.com/langchain-ai/langgraph) for workflow orchestration
- Powered by [Claude AI](https://www.anthropic.com/claude) for intelligent analysis
- Uses [PRAW](https://praw.readthedocs.io/) for Reddit integration
- Web search via [Tavily API](https://tavily.com/)

---

*Created: November 2024*